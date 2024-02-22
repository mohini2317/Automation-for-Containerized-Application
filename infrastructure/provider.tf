# Initialize Terraform and configure the AWS provider
provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Component  = "eks-demoapp-service"
      Department = "Test"
    }
  }

}

terraform {
  backend "s3" {
    bucket = "eks-tf-state-bucket-aritra-eks"
    key    = "eks-tf-state"
    region = "eu-west-1"
  }
}
