# dev environment

Adopts the existing network (VPC, Internet Gateway, NAT Gateway) and creates the `/24` subnets and route tables for the `dev` environment. Remote state lives in S3 under `aws-eks-gitops-platform/dev/terraform.tfstate`.

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars   # fill with private ids
terraform init
terraform fmt -recursive
terraform validate
terraform plan     # requires authorization before apply
```

`apply` and `destroy` require explicit authorization and a cost review (see `.ai/TOOLS.md`).

## Notes

- The VPC/IGW/NAT ids are private inputs and are never committed.
- Subnets: public `10.11.21.0/24` and `10.11.22.0/24`; private `10.11.23.0/24` and `10.11.24.0/24` (ADR-019).
- EKS, IAM, and the remaining platform resources are added in later phases.
