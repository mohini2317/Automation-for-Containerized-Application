# Initialize Terraform and configure the AWS provider
provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket = "tf-state-bucket-demo-eks"
    key    = "state/terraform.tfstate"
    region = "ap-south-1"
  }
}
