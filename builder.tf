// tf apply -var-file="codershowcase.tfvars"

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48"
    }
  }

  required_version = ">= 1.0.0"
}

variable "domain_name" {
  description = "domain name without leading dot or without www"
  type        = string
  default     = "example.com"
}

variable "profile" {
  description = "AWS user with CloudFront and S3 permissions"
  type        = string
  default     = "default"
}

variable "region" {
  description = "AWS Region for ACM"
  type        = string
  default     = "us-east-1"
}

variable "bucket" {
  description = "Preexisting S3 bucket with static web hosting (bucket) enabled"
  type        = string
  default     = ""
}

variable "logs" {
  description = "Preexisting S3 bucket for logs"
  type        = string
  default     = ""
}

variable "index_html" {
  description = "The inital HTML file to upload to the S3 bucket"
  type        = string
  default     = ""
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

data "aws_s3_bucket" "logs" {
  bucket = var.logs
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = [format("*.%s", var.domain_name)]
  lifecycle {
    create_before_destroy = true
  }
}

locals {
  s3_origin_id   = format("terraform-origin--%s", replace(var.domain_name, ".", "_"))
  s3_logs_prefix = format("cf-%s", replace(var.domain_name, ".", "_"))
}

output "s3_origin_id" {
  description = "generated from domain name"
  value       = local.s3_origin_id
}

data "aws_route53_zone" "selected" {
  name         = format("%s.", var.domain_name)
  private_zone = false
}

resource "aws_route53_record" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

resource "aws_cloudfront_origin_access_identity" "new_oai" {
  comment = format("terraform-access-ident--%s", var.domain_name)
}

output "new_oai" {
  description = "newly created OAI"
  value       = resource.aws_cloudfront_origin_access_identity.new_oai.id
}

data "aws_cloudfront_cache_policy" "cache_pol" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_function" "redir" {
  name    = "redirect_index_html"
  runtime = "cloudfront-js-1.0"
  comment = "terraform--redirect_index_html"
  publish = true
  code    = file("redirect.js")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [aws_cloudfront_origin_access_identity.new_oai, aws_s3_bucket.b, data.aws_cloudfront_cache_policy.cache_pol]
  origin {
    domain_name = resource.aws_s3_bucket.b.bucket_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = format("origin-access-identity/cloudfront/%s", resource.aws_cloudfront_origin_access_identity.new_oai.id)
    }
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = format("terraform--%s", var.domain_name)
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = data.aws_s3_bucket.logs.bucket_domain_name
    prefix          = local.s3_logs_prefix
  }

  aliases = [var.bucket, var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    cache_policy_id        = data.aws_cloudfront_cache_policy.cache_pol.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redir.arn
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = resource.aws_acm_certificate.cert.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}

output "cloudfront_site" {
  description = "The newly created cloudfront domain"
  value       = resource.aws_cloudfront_distribution.s3_distribution.domain_name
}

data "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "dns1" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "7200"
  records = ["${resource.aws_cloudfront_distribution.s3_distribution.domain_name}"]
}

resource "aws_route53_record" "dns2" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = resource.aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = resource.aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
