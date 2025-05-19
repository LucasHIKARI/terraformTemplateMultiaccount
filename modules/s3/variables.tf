variable "create_s3_bucket" {
  description = "Controls if S3 bucket should be created"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = null

  validation {
    condition     = (var.s3_bucket_name == null) || (length(var.s3_bucket_name) < 64 && lower(var.s3_bucket_name) == var.s3_bucket_name && !endswith(var.s3_bucket_name, "x-s3"))
    error_message = "Invalid S3 bucket name"
  }
}

variable "s3_bucket_object_lock" {
  description = "Whether to enable object lock for the S3 bucket."
  type        = bool
  default     = false
}

variable "s3_bucket_tags" {
  description = "The tags to assign to the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "s3_expected_bucket_owner" {
  description = "Account ID of the expected bucket owner for the bucket"
  type        = string
  default     = null
  nullable    = true
}

variable "s3_bucket_object_lock_configure" {
  description = "To set the object lock configuration for all objects in the S3 bucket"
  type = object({
    create = bool
    retation_rule = optional(object({
      days             = optional(number)
      years            = optional(number)
      object_lock_mode = string
    }))
  })
  default = {
    create = false
  }

  validation {
    condition     = var.s3_bucket_object_lock_configure.retation_rule == null ? true : !((var.s3_bucket_object_lock_configure.retation_rule.days == null && var.s3_bucket_object_lock_configure.retation_rule.years == null) || (var.s3_bucket_object_lock_configure.retation_rule.days != null && var.s3_bucket_object_lock_configure.retation_rule.years != null))
    error_message = "days and years must be sepcified only one"
  }

  validation {
    condition     = var.s3_bucket_object_lock_configure.retation_rule == null ? true : contains(["COMPLIANCE", "GOVERNANCE"], var.s3_bucket_object_lock_configure.retation_rule.object_lock_mode)
    error_message = "The object lock mode must be either COMPLIANCE or GOVERNANCE"
  }
}

variable "s3_bucket_logging" {
  description = "To configure the S3 logging bucket for the current bucket"
  type = object({
    create           = bool
    target_bucket_id = optional(string)
    target_prefix    = optional(string)
  })
  default = {
    create = false
  }
}

variable "s3_bucket_public_access_block" {
  description = "To configure the S3 bucket-level public access block for the current bucket"
  type = object({
    create                  = bool
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default = {
    create = true
  }
}

variable "s3_bucket_policy" {
  description = "To attach a policy to the current S3 bucket"
  type = object({
    create                  = bool
    aws_iam_policy_document = optional(string)
  })
  default = {
    create = false
  }
}

variable "s3_bucket_ownership_controls" {
  description = "To set the Who own objects in the current S3 bucket"
  type = object({
    create           = bool
    object_ownership = optional(string, "BucketOwnerEnforced")
  })
  default = {
    create = false
  }

  validation {
    condition     = contains(["BucketOwnerEnforced", "ObjectWriter", "BucketOwnerPreferred"], var.s3_bucket_ownership_controls.object_ownership)
    error_message = "Invliad object ownership value"
  }
}

variable "s3_bucket_accelerate_configuration" {
  description = "To set whether enable S3 bucket accelerate configuration for the current bucket"
  type = object({
    create    = bool
    is_enable = optional(bool, false)
  })
  default = {
    create = false
  }
}

variable "s3_bucket_versioning" {
  description = "To set the S3 bucket versioning configuration"
  type = object({
    create    = bool
    is_enable = optional(bool, true)
  })
  default = {
    create = false
  }
}

variable "s3_bucket_inventory" {
  description = "To set the S3 bucket inventory configuration"
  type = object({
    create                   = bool
    unique_name              = string
    included_object_versions = optional(string, "All")
    schedule_frequency       = optional(string, "Daily")
    is_enable                = optional(bool, true)
    optional_fields          = optional(set(string))
    filter                   = optional(set(string), [])
    destination_bucket = set(object({
      bucket_arn    = string
      output_format = optional(string, "CSV")
      owner_id      = optional(string)
      prefix        = optional(string, "inventory/")
      encryption = optional(object({
        sse_s3         = optional(bool)
        sse_kms_key_id = optional(string)
      }))
    }))
  })
  default = {
    create             = false
    destination_bucket = []
    unique_name        = ""
  }

  validation {
    condition     = alltrue([for v in var.s3_bucket_inventory.destination_bucket : v.encryption == null ? true : !(v.encryption.sse_s3 != null && v.encryption.sse_kms_key_id != null)])
    error_message = "sse_s3 and sse_kms_key_id must be specified only one"
  }

  validation {
    condition     = contains(["All", "Current"], var.s3_bucket_inventory.included_object_versions)
    error_message = "The value of included_object_versions must be either All or Current"
  }

  validation {
    condition     = contains(["Daily", "Weekly"], var.s3_bucket_inventory.schedule_frequency)
    error_message = "The value of schedule_frequency must be either Daily or Weekly"
  }

  validation {
    condition     = alltrue([for v in var.s3_bucket_inventory.destination_bucket : contains(["CSV", "ORC", "Parquet"], v.output_format)])
    error_message = "The value of output_format must be the one of [CSV, ORC, Parquet]"
  }

  validation {
    condition     = var.s3_bucket_inventory.create ? length(var.s3_bucket_inventory.unique_name) != 0 : true
    error_message = "The value of unique_name must be not empty"
  }
}

variable "s3_bucket_lifecycle_rule" {
  description = "To set the lifestyle rule for the current bucket"
  type = object({
    create = bool
    rule = optional(list(object({
      unique_rule_name                             = string
      is_enable                                    = optional(bool, true)
      abort_incomplete_multipart_upload_after_days = optional(list(number), [])
      expiration = optional(list(object({
        date                         = optional(string)
        days                         = optional(number)
        expired_object_delete_marker = optional(bool)
      })), [])
      noncurrent_version_expiration = optional(list(object({
        retain_numbers  = optional(string)
        noncurrent_days = number
      })), [])
      filter = optional(list(object({
        and = optional(list(object({
          object_size_greater_than = optional(number)
          object_size_less_than    = optional(number)
          prefix                   = optional(string)
          tag                      = optional(map(string))
        })), [])
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
        prefix                   = optional(string)
        tag                      = optional(map(string), {})
      })), [])
    })), [])
  })
  default = {
    create           = false
    unique_rule_name = ""
  }

  validation {
    condition     = var.s3_bucket_lifecycle_rule.create && length(var.s3_bucket_lifecycle_rule.rule) > 0 ? alltrue([for v in var.s3_bucket_lifecycle_rule.rule : length(v.unique_rule_name) > 0 && length(v.unique_rule_name) < 256]) : true
    error_message = "The length of unique_rule_name must greater than 0 and less than 256"
  }
}

variable "s3_bucket_server_side_encryption_config" {
  description = "To set server side encryption for the current bucket"
  type = object({
    create                        = bool
    sse_algorithm                 = string
    kms_master_key_id             = optional(string)
    enable_bucket_key_for_sse_kms = optional(bool)
  })
  default = {
    create        = false
    sse_algorithm = "AES256"
  }

  validation {
    condition     = contains(["AES256", "aws:kms", "aws:kms:dsse"], var.s3_bucket_server_side_encryption_config.sse_algorithm)
    error_message = "The sse algorithm only can be one of [AES256, aws:kms, aws:kms:dsse]"
  }
}

variable "s3_bucket_website_config" {
  description = "To configure the static wesite resource for the current bucket"
  type = object({
    create                  = bool
    error_document          = optional(string)
    index_document          = optional(string)
    redirect_all_request_to = optional(string)
    routing_rule = optional(list(object({
      condition = object({
        http_error_code_returened_equals = optional(number)
        key_prefix_equals                = optional(string)
      })
      redirect = object({
        host_name               = optional(string)
        http_redirect_code      = optional(string)
        protocol                = optional(string)
        replace_key_prefix_with = optional(string)
        replace_key_with        = optional(string)
      })
    })), [])
  })
  default = {
    create = false
  }

  validation {
    condition     = !(var.s3_bucket_website_config.index_document != null && var.s3_bucket_website_config.redirect_all_request_to != null)
    error_message = "Ether the index_document or the reirect_all_request_to must be specified"
  }

  validation {
    condition     = !(var.s3_bucket_website_config.redirect_all_request_to != null && var.s3_bucket_website_config.error_document != null)
    error_message = "The error_document conficts with the redirect_all_request_to"
  }

  validation {
    condition     = !(var.s3_bucket_website_config.redirect_all_request_to != null && length(var.s3_bucket_website_config.routing_rule) > 0)
    error_message = "The routing_rule conficts with the redirect_all_request_to"
  }

  validation {
    condition     = length(var.s3_bucket_website_config.routing_rule) == 0 ? true : alltrue([for v in var.s3_bucket_website_config.routing_rule : !(v.condition.http_error_code_returened_equals != null && v.condition.key_prefix_equals != null)])
    error_message = "Ether http_error_code_returned_equals or the key_prefix_equals must be specified"
  }

  validation {
    condition     = length(var.s3_bucket_website_config.routing_rule) == 0 ? true : alltrue([for v in var.s3_bucket_website_config.routing_rule : !(v.redirect.replace_key_prefix_with != null && v.redirect.replace_key_with)])
    error_message = "The replace_key_prefix_with conficts with the replace_key_with"
  }
}

variable "s3_object_upload" {
  description = "To upload the specified file at the given path"
  type = object({
    create                        = bool
    trimprefix                    = string
    absolute_path                 = set(string)
    key_prefix                    = optional(string)
    enable_replace                = optional(bool, false)
    enable_object_lock_legal_hold = optional(bool)
    object_lock_mode              = optional(string)
    tags                          = optional(map(string))
    object_lock_retain_until_date = optional(string)
    server_side_encryption        = optional(string)
    content_type                  = optional(string)
  })
  default = {
    create        = false
    absolute_path = []
    trimprefix    = ""
  }

  validation {
    condition     = var.s3_object_upload.object_lock_mode == null ? true : contains(["COMPLIANCE", "GOVERNANCE"], var.s3_object_upload.object_lock_mode)
    error_message = "The object lock mode must be either COMPLIANCE or GOVERNANCE"
  }

  validation {
    condition     = var.s3_object_upload.object_lock_retain_until_date == null ? true : try(timeadd(var.s3_object_upload.object_lock_retain_until_date, "1m"), null) != null
    error_message = "Invalid object lock retain datetime"
  }

  validation {
    condition     = var.s3_object_upload.server_side_encryption == null ? true : contains(["AES256", "aws:kms"], var.s3_object_upload.server_side_encryption)
    error_message = "The server side encryption must be either AES256 or aws:kms"
  }
}

variable "s3_object_copy_from" {
  description = "To copy object from an another bucket to the current bucket"
  type = object({
    create = bool
    entries = set(object({
      src = string
      dst = string
    }))
  })

  default = {
    create  = false
    entries = []
  }
}

variable "s3_object_copy_to" {
  description = "To copy object from the current bucket to an another bucket"
  type = object({
    create    = bool
    bucket_id = string
    source    = set(string)
  })

  default = {
    create    = false
    source    = []
    bucket_id = ""
  }

  validation {
    condition     = var.s3_object_copy_to.create ? length(var.s3_object_copy_to.bucket_id) != 0 : true
    error_message = "The value of bucket_id must not empty"
  }
}