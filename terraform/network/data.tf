# data source that queries AWS and fetches list of Availability Zones in current region, state - filters results to only return AZs that are available
data "aws_availability_zones" "available" {
  state = "available"
}

# data source that calls AWS and returns information about the identity That Terraform is currently using to authenticate (IAM role or user)
data "aws_caller_identity" "current" {}
