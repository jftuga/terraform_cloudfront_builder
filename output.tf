output "s3_origin_id" {
  description = "generated from domain name"
  value       = local.s3_origin_id
}

output "new_oai" {
  description = "newly created OAI"
  value       = resource.aws_cloudfront_origin_access_identity.new_oai.id
}

output "cloudfront_site" {
  description = "The newly created cloudfront domain"
  value       = resource.aws_cloudfront_distribution.s3_distribution.domain_name
}
