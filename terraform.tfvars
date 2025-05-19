#################################################################
#  WARNING
#               気をつけてください
#  このファイルの変数はテスト用です
#
#  開発環境ではterrafrom.dev.tfvarsを使用してください
#  本番環境ではterraform.prod.tfvarsを使用してください
#################################################################

name   = "BinahAITest"
region = "ap-northeast-1"

ec2_instance_type      = "t2.micro"
ec2_instance_ip_number = 2025
ec2_keyname            = "BinahAIDev"

vpc_cidr                   = "172.25.0.0/16"
vpc_route_destination_cidr = "0.0.0.0/0"
vpc_subnet_nums            = 4


enable_bucket_object_lock = {
  for_data    = true
  for_logger  = true
  for_website = true
}

object_lock_rule = {
  "for_data" = {
    days             = 1
    object_lock_mode = "GOVERNANCE"
  }
  "for_logger" = {
    days             = 1
    object_lock_mode = "GOVERNANCE"
  }
  "for_website" = {
    days             = 1
    object_lock_mode = "GOVERNANCE"
  }
}

enable_block_public_access = {
  "for_data" = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  "for_logger" = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  "for_website" = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

upload_website_to_s3 = {
  local_path = "../../test/client/dist"
}

upload_server_to_s3 = {
  local_path = "../../server"
}


common_tags = {
  "Environment" = "Test"
}

cdn_description = "BinahAI test"