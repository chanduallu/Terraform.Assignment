variable "region" {
  default = "ap-southeast-1"
}

variable "vpc_name" {
  default = "sbx-vpc"
}

variable "vpc_cidr" {
  default = "172.18.0.0/22"
}

variable "azs" {
  default = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "public_subnets" {
  default = ["172.18.0.0/26", "172.18.1.0/26"]
}

variable "private_subnets" {
  default = ["172.18.0.128/26", "172.18.0.64/26"]
}

