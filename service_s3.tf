locals {
  lower_name          = lower(var.name)
  name_data_bucket    = coalesce(var.name_data_bucket, "${local.lower_name}-data")
  name_logger_bucket  = coalesce(var.name_logger_bucket, "${local.lower_name}-logger")
  name_website_bucket = coalesce(var.name_website_bucket, "${local.lower_name}-website")

  bucket_tags = merge(
    { Project = "${var.name}" },
    var.s3_bucket_tags,
    var.common_tags
  )
}


#################################################################
# ユーザーデータを保存するバケット  
#################################################################

module "s3_data_bucket" {
  source = "./modules/s3"

  s3_expected_bucket_owner = var.bucket_owner_id.for_data

  create_s3_bucket      = true
  s3_bucket_name        = local.name_data_bucket
  s3_bucket_object_lock = var.enable_bucket_object_lock.for_data
  s3_bucket_tags = merge(local.bucket_tags, {
    DataType = "data"
  })

  s3_bucket_object_lock_configure = {
    create        = var.enable_bucket_object_lock.for_data
    retation_rule = var.object_lock_rule["for_data"]
  }

  s3_bucket_logging = {
    create           = true
    target_bucket_id = module.s3_logger_bucket.bucket.id
    target_prefix    = "log/${local.lower_name}/data"
  }

  s3_bucket_public_access_block = {
    create                  = true
    block_public_acls       = var.enable_block_public_access["for_data"].block_public_acls
    block_public_policy     = var.enable_block_public_access["for_data"].block_public_policy
    ignore_public_acls      = var.enable_block_public_access["for_data"].ignore_public_acls
    restrict_public_buckets = var.enable_block_public_access["for_data"].restrict_public_buckets
  }

  s3_bucket_policy = {
    create                  = true
    aws_iam_policy_document = data.aws_iam_policy_document.ec2_access_data_bucket.json
  }
  s3_bucket_ownership_controls = {
    create           = false
    object_ownership = "BucketOwnerEnforced"
  }

  s3_bucket_versioning = {
    create    = var.enable_bucket_object_lock.for_data
    is_enable = true
  }

  s3_bucket_inventory = {
    create             = true
    unique_name        = "bucket_data_invetory"
    schedule_frequency = "Daily"
    destination_bucket = [{
      bucket_arn = module.s3_logger_bucket.bucket.arn
      owner_id   = var.bucket_owner_id.for_logger
      prefix     = "inventory/${local.lower_name}/data"
      encryption = {
        sse_s3 = true
      }
    }]
  }

  s3_object_upload = {
    create         = true
    absolute_path  = [abspath(var.upload_server_to_s3.local_path)]
    trimprefix     = abspath(var.upload_server_to_s3.local_path)
    key_prefix     = "server"
    enable_replace = var.enable_bucket_object_lock.for_data

    tags = merge(
      { Project = "${var.name}" },
      { Type = "Server" },
      { Type1 = "SourceCode" },
    )
  }

  s3_bucket_lifecycle_rule = {
    create = true
    rule = [
      {
        unique_rule_name = "${local.lower_name}-delete-old-version"
        noncurrent_version_expiration = [
          {
            retain_numbers  = 1
            noncurrent_days = 1
          }
        ]
        filter = [
          {
            prefix = "health/"
          }
        ]
      }
    ]
  }
}


#################################################################
# システムの運行の情報を保存するバケット  
#################################################################
module "s3_logger_bucket" {
  source = "./modules/s3"

  s3_expected_bucket_owner = var.bucket_owner_id.for_logger

  create_s3_bucket      = true
  s3_bucket_name        = local.name_logger_bucket
  s3_bucket_object_lock = var.enable_bucket_object_lock.for_logger
  s3_bucket_tags = merge(local.bucket_tags, {
    DataType = "log"
  })

  s3_bucket_object_lock_configure = {
    create        = var.enable_bucket_object_lock.for_logger
    retation_rule = var.object_lock_rule["for_logger"]
  }

  s3_bucket_public_access_block = {
    create                  = true
    block_public_acls       = var.enable_block_public_access["for_logger"].block_public_acls
    block_public_policy     = var.enable_block_public_access["for_logger"].block_public_policy
    ignore_public_acls      = var.enable_block_public_access["for_logger"].ignore_public_acls
    restrict_public_buckets = var.enable_block_public_access["for_logger"].restrict_public_buckets
  }

  s3_bucket_policy = {
    create                  = true
    aws_iam_policy_document = data.aws_iam_policy_document.ec2_access_logger_bucket.json
  }
  s3_bucket_ownership_controls = {
    create           = false
    object_ownership = "BucketOwnerEnforced"
  }

  s3_bucket_versioning = {
    create    = var.enable_bucket_object_lock.for_logger
    is_enable = true
  }

  s3_bucket_lifecycle_rule = {
    create = true
    rule = [
      {
        unique_rule_name                             = "server-log"
        is_enable                                    = true
        abort_incomplete_multipart_upload_after_days = [1]
        expiration = [{
          days = 730
        }]
        filter = [{
          prefix = "log/${local.lower_name}/server"
        }]
      },
      {
        unique_rule_name                             = "website-log"
        is_enable                                    = true
        abort_incomplete_multipart_upload_after_days = [1]
        expiration = [{
          days = 365
        }]
        filter = [{
          prefix = "log/${local.lower_name}/website"
        }]
      }
    ]
  }
}


#################################################################
# ウエブサイトのスタティックリソースを保存するバケット  
#################################################################
module "s3_website_bucket" {
  source = "./modules/s3"

  s3_expected_bucket_owner = var.bucket_owner_id.for_website

  create_s3_bucket      = true
  s3_bucket_name        = local.name_website_bucket
  s3_bucket_object_lock = var.enable_bucket_object_lock.for_website
  s3_bucket_tags = merge(local.bucket_tags, {
    DataType = "website"
  })

  s3_bucket_object_lock_configure = {
    create        = var.enable_bucket_object_lock.for_website
    retation_rule = var.object_lock_rule["for_website"]
  }

  s3_bucket_logging = {
    create           = true
    target_bucket_id = module.s3_logger_bucket.bucket.id
    target_prefix    = "log/${local.lower_name}/website"
  }

  s3_bucket_public_access_block = {
    create                  = true
    block_public_acls       = var.enable_block_public_access["for_website"].block_public_acls
    block_public_policy     = var.enable_block_public_access["for_website"].block_public_policy
    ignore_public_acls      = var.enable_block_public_access["for_website"].ignore_public_acls
    restrict_public_buckets = var.enable_block_public_access["for_website"].restrict_public_buckets
  }

  s3_bucket_policy = {
    create                  = true
    aws_iam_policy_document = data.aws_iam_policy_document.https.json
  }
  s3_bucket_ownership_controls = {
    create           = false
    object_ownership = "BucketOwnerEnforced"
  }

  s3_bucket_inventory = {
    create             = true
    unique_name        = "bucket_data_invetory"
    schedule_frequency = "Weekly"
    destination_bucket = [{
      bucket_arn = module.s3_logger_bucket.bucket.arn
      owner_id   = var.bucket_owner_id.for_logger
      prefix     = "inventory/${local.lower_name}/data"
      encryption = {
        sse_s3 = true
      }
    }]
  }

  s3_object_upload = {
    create         = true
    absolute_path  = [abspath(var.upload_website_to_s3.local_path)]
    trimprefix     = abspath(var.upload_website_to_s3.local_path)
    enable_replace = var.enable_bucket_object_lock.for_website

    tags = merge(
      { Project = "${var.name}" },
      { Type = "Website" },
      { Type1 = "Frontend" },
      { Type2 = "StaticResource" }
    )
  }

  s3_bucket_website_config = {
    create         = true
    index_document = "index.html"
    error_document = "index.html"
  }
}