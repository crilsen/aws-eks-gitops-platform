terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state in S3, one folder per environment (ADR-017).
  # Native S3 locking via use_lockfile avoids a DynamoDB table.
  backend "s3" {
    bucket       = "cn-terraform-state-us-east-1"
    key          = "aws-eks-gitops-platform/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
