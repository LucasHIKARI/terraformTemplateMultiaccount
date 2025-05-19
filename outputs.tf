output "website" {
  description = "ウェブサイトの情報を出力"
  value = {
    id                  = module.s3_website_bucket.website.id
    website_domain      = module.s3_website_bucket.website.website_domain
    website_endpoint    = module.s3_website_bucket.website.website_endpoint
    domain_name         = module.cdn.cloudfront.distribution.domain_name
    role                = module.iam.role
    policy              = module.iam.policy
    service_profile     = module.iam.service_profile
    policy_role_mapping = module.iam.policy_role_mapping
    data_bucket_name    = module.s3_data_bucket.bucket.bucket_name
  }
}

output "website_url" {
  description = "ウェブサイトのURLを出力"
  value       = module.cdn.cloudfront.distribution.domain_name
}