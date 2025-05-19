provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}


locals {
  available_zones      = slice(data.aws_availability_zones.available_zones.names, 0, 3)
  vpc_net_mask         = tonumber(regex("^.*/(\\d+)$", var.vpc_cidr)[0])
  vpc_subnet_nums      = ceil(log(var.vpc_subnet_nums, 2))
  vpc_subnet_total_ips = pow(2, 32 - local.vpc_net_mask - log(local.vpc_subnet_nums, 2))
}
