data "aws_iam_policy_document" "public" {
  policy_id = "bucket_policy_for_public"
  statement {
    sid     = "PublicAccessWebsite"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${module.s3_website_bucket.bucket.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# cloudfront --------------->    s3(website bucket)
data "aws_iam_policy_document" "https" {
  policy_id = "bucket_policy_for_https"
  statement {
    sid     = "AccessWebsiteByHTTPs"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${module.s3_website_bucket.bucket.arn}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        module.cdn.cloudfront.distribution.arn
      ]
    }
  }
}

# EC2 --------------------------------> s3(data bucket)
data "aws_iam_policy_document" "ec2_access_data_bucket" {
  policy_id = "data_bucket_policy_for_ec2"
  statement {
    sid    = "AccessDataBucketObjectForEC2"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObjectTagging",
      "s3:PutObject",
    ]
    resources = [
      "${module.s3_data_bucket.bucket.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["${module.iam.role[local.role_idx_ec2].arn}"]
    }
  }
  statement {
    sid    = "AccessDataBucketForEC2"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${module.s3_data_bucket.bucket.arn}"
    ]
    principals {
      type        = "AWS"
      identifiers = ["${module.iam.role[local.role_idx_ec2].arn}"]
    }
  }
}

# EC2 --------------------------------> s3(logger bucket)
data "aws_iam_policy_document" "ec2_access_logger_bucket" {
  policy_id = "data_bucket_policy_for_ec2"
  statement {
    sid    = "AccessDataBucketObjectForEC2"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
    ]
    resources = [
      "${module.s3_logger_bucket.bucket.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["${module.iam.role[local.role_idx_ec2].arn}"]
    }
  }
  statement {
    sid    = "AccessDataBucketForEC2"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${module.s3_logger_bucket.bucket.arn}"
    ]
    principals {
      type        = "AWS"
      identifiers = ["${module.iam.role[local.role_idx_ec2].arn}"]
    }
  }
  statement {
    sid    = "AccessLoggerBucketObjectForALB"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${module.s3_logger_bucket.bucket.arn}/*"
    ]
  }
}


data "aws_iam_policy_document" "ec2_assume_role_policy" {
  policy_id = "assume_role_policy_for_ec2_role"
  statement {
    sid     = "AssumeRolePolicyForEC2Role"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_access_s3" {
  policy_id = "policy_for_ec2_access_s3"
  statement {
    sid    = "EC2AccessS3DataBucketPolicy"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:ListBucket"
    ]
    resources = [
      "${module.s3_data_bucket.bucket.arn}/*"
    ]
  }

  statement {
    sid    = "EC2AccessS3LoggerBucketPolicy"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:PutObjectTagging",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.s3_logger_bucket.bucket.arn}/*"
    ]
  }
}