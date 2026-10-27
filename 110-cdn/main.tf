resource "aws_cloudfront_distribution" "expense" {
  origin {
    domain_name              = "${var.project_name}-${var.environment}.${var.zone_name}"
    origin_id                = "${var.project_name}-${var.environment}.${var.zone_name}"

    custom_origin_config {
        http_port = 80
        https_port = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocol = ["TLSv1.2"]
    }
  }

  enabled             = true

  aliases = ["${var.project_name}-cdn.${var.zone_name}"]
  
  # dynamic content, evaluated at last no cache
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.project_name}-${var.environment}.${var.zone_name}"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    cache_policy_id        = data.aws_cloudfront_cache_policy.noCache.id
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/images/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${var.project_name}-${var.environment}.${var.zone_name}"

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.cacheOptimized.id
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.project_name}-${var.environment}.${var.zone_name}"

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.cacheOptimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN", "CA", "GB", "DE"]
    }
  }

  tags = merge(
    var.common_tags,
    {
        Name = local.resource_name
    }

  )

  viewer_certificate {
    acm_certificate_arn = local.https_certificate_arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Create Route53 records for the CloudFront distribution aliases
module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "4.1.0"

  zone_name = var.zone_name

  records = [
    {
      name = "expense-cdn"
      type = "A"

      alias = {
        name                   = aws_cloudfront_distribution.domain_name
        zone_id                = aws_cloudfront_distribution_hosted_zone_id # This belongs CDN internal hosted zone, not ours
      }

      allow_overwrite = true
    }
  ]
}

# See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
# data "aws_iam_policy_document" "origin_bucket_policy" {
#   statement {
#     sid    = "AllowCloudFrontServicePrincipalReadWrite"
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["cloudfront.amazonaws.com"]
#     }

#     actions = [
#       "s3:GetObject",
#       "s3:PutObject",
#     ]

#     resources = [
#       "${aws_s3_bucket.b.arn}/*",
#     ]

#     condition {
#       test     = "StringEquals"
#       variable = "AWS:SourceArn"
#       values   = [aws_cloudfront_distribution.s3_distribution.arn]
#     }
#   }
# }

# resource "aws_s3_bucket_policy" "b" {
#   bucket = aws_s3_bucket.b.bucket
#   policy = data.aws_iam_policy_document.origin_bucket_policy.json
# }

# locals {
#   s3_origin_id = "myS3Origin"
#   my_domain    = "mydomain.com"
# }

# data "aws_acm_certificate" "my_domain" {
#   region   = "us-east-1"
#   domain   = "*.${local.my_domain}"
#   statuses = ["ISSUED"]
# }

# resource "aws_cloudfront_origin_access_control" "default" {
#   name                              = "default-oac"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }