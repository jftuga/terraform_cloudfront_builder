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
