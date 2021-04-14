## terraform backend configuration ##

terraform {
  backend "s3" {
    bucket = "terraform-sbx-s3"
    key    = "sbx-vpc/statefile.tfstate"
    region = "ap-southeast-1"
#    kms_key_id = ""  ## use kms key id if s3 bucket is encrypted with a specific key 
  }
}

## Infra provider configuration ##

provider "aws" {
  region = var.region
}

#########
# VPC
#########

module "vpc" {
  source             = "../Modules/vpc"
  name               = var.vpc_name
  cidr               = var.vpc_cidr
  azs                = var.azs
  single_nat_gateway = true
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

