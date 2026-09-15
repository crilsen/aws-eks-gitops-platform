locals {
  vpc_id = var.create_vpc ? aws_vpc.this[0].id : var.vpc_id

  igw_id = var.internet_gateway_id != null ? var.internet_gateway_id : try(aws_internet_gateway.this[0].id, null)

  create_nat = var.enable_nat_gateway && var.nat_gateway_id == null
  nat_id     = var.nat_gateway_id != null ? var.nat_gateway_id : try(aws_nat_gateway.this[0].id, null)

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    tostring(idx) => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    tostring(idx) => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }
}

resource "terraform_data" "validate" {
  lifecycle {
    precondition {
      condition     = var.create_vpc || var.vpc_id != null
      error_message = "vpc_id must be provided when create_vpc is false."
    }

    precondition {
      condition     = length(var.public_subnet_cidrs) <= length(var.azs) && length(var.private_subnet_cidrs) <= length(var.azs)
      error_message = "The number of subnet CIDRs cannot exceed the number of availability zones."
    }
  }
}

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  count = var.create_igw && var.internet_gateway_id == null ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = local.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.value.az}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.value.az}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  count = local.create_nat ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count = local.create_nat ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[tostring(0)].id

  tags = merge(var.tags, { Name = "${var.name}-nat" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  count = local.igw_id != null ? 1 : 0

  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.igw_id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = local.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route" "private_nat" {
  count = local.nat_id != null ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.nat_id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
