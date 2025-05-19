
output "bucket" {
  description = "The information for the current S3 bucket"
  value = {
    id                          = try(aws_s3_bucket.this[0].id, null)
    arn                         = try(aws_s3_bucket.this[0].arn, null)
    bucket_domain_name          = try(aws_s3_bucket.this[0].bucket_domain_name, null)
    region                      = try(aws_s3_bucket.this[0].region, null)
    bucket_regional_domain_name = try(aws_s3_bucket.this[0].bucket_regional_domain_name, null)
    hosted_zone_id              = try(aws_s3_bucket.this[0].hosted_zone_id, null)
    bucket_name                 = try(aws_s3_bucket.this[0].bucket, null)
  }
}

output "website" {
  description = "The information for the static website"
  value = {
    id               = try(aws_s3_bucket_website_configuration.this[0].id, null)
    website_domain   = try(aws_s3_bucket_website_configuration.this[0].website_domain, null)
    website_endpoint = try(aws_s3_bucket_website_configuration.this[0].website_endpoint, null)
  }
}