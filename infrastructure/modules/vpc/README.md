# VPC module

Create a VPC or adopt an existing one, create `/24` subnets, reuse or create an Internet Gateway and a NAT Gateway, and **always** create the route tables (ADR-013).

## Behavior

- **VPC:** set `create_vpc = true` to create from `vpc_cidr`, or `create_vpc = false` and pass `vpc_id` to adopt.
- **Subnets:** created by the module from `public_subnet_cidrs` and `private_subnet_cidrs`, one per entry in `azs`.
- **Internet Gateway:** pass `internet_gateway_id` to reuse, or leave `create_igw = true` to create one.
- **NAT Gateway:** pass `nat_gateway_id` to reuse; creation is off by default (`enable_nat_gateway = false`) to avoid cost.
- **Route tables:** always created and owned by the module. The public table routes `0.0.0.0/0` to the IGW; the private table routes `0.0.0.0/0` to the NAT when one exists.

## Example — adopt an existing network

```hcl
module "vpc" {
  source = "../modules/vpc"

  name = "aws-eks-gitops-platform-dev"
  tags = local.tags

  create_vpc = false
  vpc_id     = var.vpc_id

  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.12.21.0/24", "10.12.22.0/24"]
  private_subnet_cidrs = ["10.12.23.0/24", "10.12.24.0/24"]

  internet_gateway_id = var.internet_gateway_id
  nat_gateway_id      = var.nat_gateway_id
}
```

## Example — create a new network

```hcl
module "vpc" {
  source = "../modules/vpc"

  name = "aws-eks-gitops-platform-dev"
  tags = local.tags

  create_vpc = true
  vpc_cidr   = "10.12.0.0/16"

  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.12.21.0/24", "10.12.22.0/24"]
  private_subnet_cidrs = ["10.12.23.0/24", "10.12.24.0/24"]
}
```

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | — | Name prefix for created resources. |
| `tags` | `map(string)` | `{}` | Tags applied to every resource. |
| `create_vpc` | `bool` | `false` | Create a VPC instead of adopting one. |
| `vpc_id` | `string` | `null` | Existing VPC id when `create_vpc = false`. |
| `vpc_cidr` | `string` | `10.11.0.0/16` | VPC CIDR when `create_vpc = true`. |
| `azs` | `list(string)` | — | At least two availability zones. |
| `public_subnet_cidrs` | `list(string)` | `[]` | Public subnet CIDRs, one per AZ. |
| `private_subnet_cidrs` | `list(string)` | `[]` | Private subnet CIDRs, one per AZ. |
| `map_public_ip_on_launch` | `bool` | `true` | Assign public IPs in public subnets. |
| `create_igw` | `bool` | `true` | Create an IGW when none is supplied. |
| `internet_gateway_id` | `string` | `null` | Existing IGW to reuse. |
| `enable_nat_gateway` | `bool` | `false` | Create a NAT Gateway when none is supplied. |
| `nat_gateway_id` | `string` | `null` | Existing NAT Gateway to reuse. |

## Outputs

`vpc_id`, `vpc_cidr`, `public_subnet_ids`, `private_subnet_ids`, `internet_gateway_id`, `nat_gateway_id`, `public_route_table_id`, `private_route_table_id`.
