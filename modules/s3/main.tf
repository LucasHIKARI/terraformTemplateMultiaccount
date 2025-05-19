resource "aws_s3_bucket" "this" {
  count = var.create_s3_bucket ? 1 : 0

  bucket              = var.s3_bucket_name
  force_destroy       = false
  object_lock_enabled = var.s3_bucket_object_lock

  tags = merge(
    { Name = "${var.s3_bucket_name}" },
    var.s3_bucket_tags
  )
}

locals {
  s3_bucket_object_lock_config_rule = var.s3_bucket_object_lock_configure.retation_rule == null ? [] : [{
    days  = var.s3_bucket_object_lock_configure.retation_rule.days
    years = var.s3_bucket_object_lock_configure.retation_rule.years
    mode  = var.s3_bucket_object_lock_configure.retation_rule.object_lock_mode
  }]
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.create_s3_bucket && var.s3_bucket_object_lock_configure.create ? 1 : 0

  bucket                = aws_s3_bucket.this[0].id
  expected_bucket_owner = var.s3_expected_bucket_owner

  dynamic "rule" {
    for_each = local.s3_bucket_object_lock_config_rule

    content {
      default_retention {
        days  = rule.value.days
        years = rule.value.years
        mode  = rule.value.mode
      }
    }
  }
}


locals {
  s3_bucket_name                  = try(aws_s3_bucket.this[0].id, "")
  s3_bucket_logging_target_prefix = coalesce(var.s3_bucket_logging.target_prefix, "log/${local.s3_bucket_name}")
}

resource "aws_s3_bucket_logging" "name" {
  count = var.create_s3_bucket && var.s3_bucket_logging.create ? 1 : 0

  bucket                = aws_s3_bucket.this[0].id
  expected_bucket_owner = var.s3_expected_bucket_owner
  target_bucket         = var.s3_bucket_logging.target_bucket_id
  target_prefix         = local.s3_bucket_logging_target_prefix
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create_s3_bucket && var.s3_bucket_public_access_block.create ? 1 : 0

  bucket                  = aws_s3_bucket.this[0].id
  block_public_acls       = var.s3_bucket_public_access_block.block_public_acls
  block_public_policy     = var.s3_bucket_public_access_block.block_public_policy
  ignore_public_acls      = var.s3_bucket_public_access_block.ignore_public_acls
  restrict_public_buckets = var.s3_bucket_public_access_block.restrict_public_buckets
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create_s3_bucket && var.s3_bucket_policy.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = var.s3_bucket_policy.aws_iam_policy_document

  depends_on = [
    aws_s3_bucket_public_access_block.this
  ]
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = var.create_s3_bucket && var.s3_bucket_ownership_controls.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  rule {
    object_ownership = var.s3_bucket_ownership_controls.object_ownership
  }

  depends_on = [
    aws_s3_bucket_public_access_block.this,
    aws_s3_bucket_policy.this,
    aws_s3_bucket.this
  ]
}

locals {
  s3_bucket_accelerate_configuration_status = var.s3_bucket_accelerate_configuration.is_enable ? "Enabled" : "Suspended"
}

resource "aws_s3_bucket_accelerate_configuration" "this" {
  count = var.create_s3_bucket && var.s3_bucket_accelerate_configuration.create ? 1 : 0

  bucket                = aws_s3_bucket.this[0].id
  expected_bucket_owner = var.s3_expected_bucket_owner
  status                = local.s3_bucket_accelerate_configuration_status
}

locals {
  create_s3_bucket_versioning = var.create_s3_bucket ? (var.s3_bucket_object_lock ? true : var.s3_bucket_versioning.create) : false
  s3_bucket_versioning_status = var.s3_bucket_versioning.is_enable ? "Enabled" : "Suspended"
}

resource "aws_s3_bucket_versioning" "this" {
  count = local.create_s3_bucket_versioning ? 1 : 0

  bucket                = aws_s3_bucket.this[0].id
  expected_bucket_owner = var.s3_expected_bucket_owner
  versioning_configuration {
    status = local.s3_bucket_versioning_status
  }
}

locals {
  s3_bucket_invertory_dst_bkt = [for v in var.s3_bucket_inventory.destination_bucket : merge(v, {
    sse_s3         = v.encryption == null ? [] : (v.encryption.sse_s3 ? [1] : [])
    sse_kms_key_id = v.encryption == null ? [] : (v.encryption.sse_kms_key_id != null ? [v.encryption.sse_kms_key_d] : [])
  })]
}

resource "aws_s3_bucket_inventory" "this" {
  count = var.create_s3_bucket && var.s3_bucket_inventory.create ? 1 : 0

  bucket                   = aws_s3_bucket.this[0].id
  name                     = var.s3_bucket_inventory.unique_name
  included_object_versions = var.s3_bucket_inventory.included_object_versions
  schedule {
    frequency = var.s3_bucket_inventory.schedule_frequency
  }
  enabled         = var.s3_bucket_inventory.is_enable
  optional_fields = var.s3_bucket_inventory.optional_fields

  dynamic "destination" {
    for_each = local.s3_bucket_invertory_dst_bkt

    content {
      bucket {
        bucket_arn = destination.value.bucket_arn
        format     = destination.value.output_format
        account_id = destination.value.owner_id
        prefix     = destination.value.prefix
        encryption {
          dynamic "sse_s3" {
            for_each = destination.value.sse_s3
            content {
            }
          }
          dynamic "sse_kms" {
            for_each = destination.value.sse_kms_key_id
            content {
              key_id = sse_kms.value
            }
          }
        }
      }
    }
  }

  dynamic "filter" {
    for_each = var.s3_bucket_inventory.filter
    content {
      prefix = filter.value
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create_s3_bucket && var.s3_bucket_lifecycle_rule.create ? 1 : 0

  bucket                = aws_s3_bucket.this[0].id
  expected_bucket_owner = var.s3_expected_bucket_owner
  dynamic "rule" {
    for_each = var.s3_bucket_lifecycle_rule.rule

    content {
      id     = rule.value.unique_rule_name
      status = rule.value.is_enable ? "Enabled" : "Disabled"

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_after_days
        iterator = days_after_initiation

        content {
          days_after_initiation = days_after_initiation.value
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration

        content {
          date                         = expiration.value.date
          days                         = expiration.value.days
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration

        content {
          newer_noncurrent_versions = noncurrent_version_expiration.value.retain_numbers
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      dynamic "filter" {
        for_each = rule.value.filter

        content {
          object_size_greater_than = filter.value.object_size_greater_than
          object_size_less_than    = filter.value.object_size_less_than
          prefix                   = filter.value.prefix

          dynamic "tag" {
            for_each = filter.value.tag

            content {
              key   = tag.key
              value = tag.value
            }
          }

          dynamic "and" {
            for_each = filter.value.and

            content {
              object_size_greater_than = and.value.object_size_greater_than
              object_size_less_than    = and.value.object_size_less_than
              prefix                   = and.value.prefix
              tags                     = and.value.tag
            }
          }
        }
      }
    }
  }
}

locals {
  website_index    = var.s3_bucket_website_config.index_document == null ? [] : [var.s3_bucket_website_config.index_document]
  website_error    = var.s3_bucket_website_config.error_document == null ? [] : [var.s3_bucket_website_config.error_document]
  website_redirect = var.s3_bucket_website_config.redirect_all_request_to == null ? [] : [var.s3_bucket_website_config.redirect_all_request_to]
}

resource "aws_s3_bucket_website_configuration" "this" {
  count = var.create_s3_bucket && var.s3_bucket_website_config.create ? 1 : 0

  bucket                = aws_s3_bucket.this[0].id
  expected_bucket_owner = var.s3_expected_bucket_owner

  dynamic "index_document" {
    for_each = local.website_index

    content {
      suffix = index_document.value
    }
  }

  dynamic "error_document" {
    for_each = local.website_error

    content {
      key = error_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = local.website_redirect

    content {
      host_name = redirect_all_requests_to.value
    }
  }

  dynamic "routing_rule" {
    for_each = var.s3_bucket_website_config.routing_rule

    content {
      condition {
        http_error_code_returned_equals = routing_rule.condition.http_error_code_returened_equals
        key_prefix_equals               = routing_rule.condition.key_prefix_equals
      }

      redirect {
        host_name               = routing_rule.redirect.host_name
        http_redirect_code      = routing_rule.redirect.http_redirect_code
        protocol                = routing_rule.redirect.protocol
        replace_key_prefix_with = routing_rule.redirect.replace_key_prefix_with
        replace_key_with        = routing_rule.redirect.replace_key_with
      }
    }
  }
}

locals {
  create_s3_object            = var.create_s3_bucket && var.s3_object_upload.create
  all_files                   = toset(local.create_s3_object ? flatten([for p in var.s3_object_upload.absolute_path : try(fileexists(p), false) ? [p] : [for f in fileset(p, "**") : abspath("${var.s3_object_upload.trimprefix}/${f}")]]) : [])
  s3_object_legal_hold_status = var.s3_object_upload.enable_object_lock_legal_hold == null ? null : (var.s3_object_upload.enable_object_lock_legal_hold ? "ON" : "OFF")
  content_type_map = {
    svg  = "image/svg+xml"
    css  = "text/css"
    js   = "text/javascript"
    json = "application/json"
    htm  = "text/html"
    html = "text/html"
    png  = "image/png"
    zip  = "application/zip"
  }
}

resource "aws_s3_object" "this" {
  for_each = local.all_files

  bucket                        = aws_s3_bucket.this[0].id
  key                           = var.s3_object_upload.key_prefix == null ? trimprefix(trimprefix(each.value, var.s3_object_upload.trimprefix), "/") : format("%s/%s", var.s3_object_upload.key_prefix, trimprefix(trimprefix(each.value, var.s3_object_upload.trimprefix), "/"))
  force_destroy                 = var.s3_object_upload.enable_replace
  object_lock_legal_hold_status = local.s3_object_legal_hold_status
  object_lock_mode              = var.s3_object_upload.object_lock_mode
  object_lock_retain_until_date = var.s3_object_upload.object_lock_retain_until_date
  server_side_encryption        = var.s3_object_upload.server_side_encryption
  source                        = each.value
  content_type                  = var.s3_object_upload.content_type != null ? var.s3_object_upload.content_type : try(local.content_type_map[regex(".*\\.([^.]+)$", basename(each.value))[0]], null)
  source_hash                   = filesha256(each.value)

  tags = var.s3_object_upload.tags
}

locals {
  create_copy_from = var.create_s3_bucket && var.s3_object_copy_from.create
  copy_frome_files = local.create_copy_from ? var.s3_object_copy_from.entries : []
}

resource "aws_s3_object_copy" "copy_from" {
  for_each = local.copy_frome_files

  bucket = aws_s3_bucket.this[0].id
  key    = each.value.dst
  source = each.value.src
}

locals {
  create_copy_to = var.create_s3_bucket && var.s3_object_copy_to.create
  copy_to_files  = local.create_copy_to ? var.s3_object_copy_to.source : []
}

resource "aws_s3_object_copy" "copy_to" {
  for_each = local.copy_to_files

  bucket = var.s3_object_copy_to.bucket_id
  key    = each.value
  source = each.value
}