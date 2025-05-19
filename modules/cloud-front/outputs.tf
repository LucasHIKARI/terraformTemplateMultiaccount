
output "cloudfront" {
  description = "The configure information for the CloudFront"
  value = {
    origin_access_control = {
      id   = try(aws_cloudfront_origin_access_control.this[0].id, null)
      etag = try(aws_cloudfront_origin_access_control.this[0].etag, null)
      arn  = try(aws_cloudfront_origin_access_control.this[0].arn, null)
    }
    vpc_origin = {
      id   = try(aws_cloudfront_vpc_origin.this[0].id, null)
      etag = try(aws_cloudfront_vpc_origin.this[0].id, null)
      arn  = try(aws_cloudfront_vpc_origin.this[0].arn, null)
    }
    monitoring_subscription = {
      id = try(aws_cloudfront_monitoring_subscription.this[0].id, null)
    }
    request_policy = {
      id   = try(aws_cloudfront_origin_request_policy.this[*].id, null)
      etag = try(aws_cloudfront_origin_request_policy.this[*].etag, null)
      arn  = try(aws_cloudfront_origin_request_policy.this[*].arn, null)
    }
    response_headers_policy = {
      id   = try(aws_cloudfront_response_headers_policy.this[*].id, null)
      etag = try(aws_cloudfront_response_headers_policy.this[*].etag, null)
      arn  = try(aws_cloudfront_response_headers_policy.this[*].arn, null)
    }
    cache_policy = {
      id   = try(aws_cloudfront_cache_policy.this[*].id, null)
      etag = try(aws_cloudfront_cache_policy.this[*].etag, null)
      arn  = try(aws_cloudfront_cache_policy.this[*].arn, null)
    }
    distribution = {
      id                            = try(aws_cloudfront_distribution.this[0].id, null)
      arn                           = try(aws_cloudfront_distribution.this[0].arn, null)
      status                        = try(aws_cloudfront_distribution.this[0].status, null)
      domain_name                   = try(aws_cloudfront_distribution.this[0].domain_name, null)
      in_progress_vlidation_batches = try(aws_cloudfront_distribution.this[0].in_progress_validation_batches, null)
      etag                          = try(aws_cloudfront_distribution.this[0].etag, null)
      hosted_zone_id                = try(aws_cloudfront_distribution.this[0].hosted_zone_id, null)
    }
    acm_certificate = {
      id                     = try(aws_acm_certificate.this[0].id, null)
      arn                    = try(aws_acm_certificate.this[0].arn, null)
      domain_name            = try(aws_acm_certificate.this[0].domain_name, null)
      status                 = try(aws_acm_certificate.this[0].status, null)
      type                   = try(aws_acm_certificate.this[0].type, null)
      validated_domain_name  = try(aws_acm_certificate.this[0].domain_validation_options[*].domain_name, null)
      validated_record_name  = try(aws_acm_certificate.this[0].domain_validation_options[*].resource_record_name, null)
      validated_record_type  = try(aws_acm_certificate.this[0].domain_validation_options[*].resource_record_type, null)
      validated_record_value = try(aws_acm_certificate.this[0].domain_validation_options[*].resource_record_value, null)
    }
  }
}