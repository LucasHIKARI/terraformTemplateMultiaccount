
# https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/vpc-cidr-blocks.html
variable "vpc_cidr" {
  description = "IPv4 CIDR(Classless Inter-Domain Routing) ブロックを指定する"
  type        = string
  nullable    = false

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Invalid CIDR for the VPC"
  }
}

variable "vpc_tags" {
  description = "VPCインスタンスに付けるタブ"
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
  description = "VPCの名前"
  type        = string
  default     = null
}

variable "vpc_route_destination_cidr" {
  description = "VPCのルート目的CIDR"
  type        = string
  default     = "0.0.0.0/0"
  nullable    = true
}

variable "vpc_subnet_nums" {
  description = "VPCのサブネット数を指定する"
  type        = number
  default     = 4
  nullable    = false

  validation {
    condition     = ceil(log(var.vpc_subnet_nums, 2)) >= 0 && ceil(log(var.vpc_subnet_nums, 2)) < pow(2, 31 - local.vpc_net_mask)
    error_message = "Invalid subnet numbers"
  }
}
