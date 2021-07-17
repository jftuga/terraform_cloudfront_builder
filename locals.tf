locals {
  s3_origin_id   = format("terraform-origin--%s", replace(var.domain_name, ".", "_"))
  s3_logs_prefix = format("cf-%s", replace(var.domain_name, ".", "_"))
}
