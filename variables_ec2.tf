variable "ec2_name" {
  description = "EC2インスタンスの名前"
  type        = string
  default     = null
}

variable "ec2_tags" {
  description = "EC2インスタンスに付けるタグ"
  type        = map(string)
  default     = null
}

# インスタンス型の参照先　https://aws.amazon.com/ec2/instance-types/
variable "ec2_instance_type" {
  description = "EC2インスタンスの型"
  type        = string
  nullable    = false
}

variable "ec2_instance_subnet_num" {
  description = "VPC内の何番目のサブネットをEC2インスタンスのサブネットとして指定する"
  type        = number
  default     = 0

  validation {
    condition     = var.ec2_instance_subnet_num >= 0 && var.ec2_instance_subnet_num <= length(local.subnets_cidr)
    error_message = "Invalid subnet number for the EC2 instance"
  }
}

variable "ec2_instance_ip_number" {
  description = "サブネット内の何番目のIPアドレスをEC2インスタンスのIPとして指定する"
  type        = number
  default     = 1

  validation {
    condition     = var.ec2_instance_ip_number > 0 && var.ec2_instance_ip_number < local.vpc_subnet_total_ips
    error_message = "Invalid IP number"
  }
}

variable "ec2_keyname" {
  description = "SSHログイン用のキー名"
  type        = string
  default     = null
  nullable    = true
}

