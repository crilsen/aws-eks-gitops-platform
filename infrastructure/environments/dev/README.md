# dev environment

Creates the network (VPC, Internet Gateway, NAT Gateway — or adopts existing ones), the `/24` subnets and route tables, the shared EKS cluster, and imports the application TLS certificate into ACM for the `dev` environment. Remote state lives in S3 under `aws-eks-gitops-platform/dev/terraform.tfstate`.

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
- Subnets: public `10.12.21.0/24` and `10.12.22.0/24`; private `10.12.23.0/24` and `10.12.24.0/24` (ADR-019).
- EKS, IAM, and the remaining platform resources are added in later phases.

## TLS (ALB HTTPS)

Terraform imports the user-supplied certificate into ACM (`aws_acm_certificate.app`):

1. Place the files in `cert/` (gitignored, never committed):
   - `cert/fullchain.pem` — leaf certificate + intermediates
   - `cert/privkey.pem` — private key matching the leaf
2. The AWS Load Balancer Controller discovers the certificate automatically by
   Ingress hostname (certificate discovery), so no ARN is committed in GitOps.
3. Renew the certificate out-of-band before expiry and re-apply; `create_before_destroy` avoids downtime on replacement.
