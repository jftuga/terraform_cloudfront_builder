data "aws_s3_bucket" "logs" {
  bucket = var.logs
}

data "aws_route53_zone" "selected" {
  name         = format("%s.", var.domain_name)
  private_zone = false
}

data "aws_cloudfront_cache_policy" "cache_pol" {
  name = "Managed-CachingOptimized"
}

data "aws_route53_zone" "primary" {
  name = var.domain_name
}
