resource "aws_s3_bucket" "b" {
  bucket = var.bucket
  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.logs
    target_prefix = format("s3-%s/", replace(var.domain_name, ".", "_"))
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  policy = jsonencode(
    {
      "Version" : "2008-10-17",
      "Id" : "PolicyForCloudFrontPrivateContent",
      "Statement" : [
        {
          "Sid" : "1",
          "Effect" : "Allow",
          "Principal" : {
            //"AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${resource.aws_cloudfront_origin_access_identity.new_oai.id}"
            "AWS" : "${resource.aws_cloudfront_origin_access_identity.new_oai.iam_arn}"
          },
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::www.${var.domain_name}/*"
        }
      ]
  })
  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = 60
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access" {
  bucket = aws_s3_bucket.b.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "object" {
  bucket = var.bucket
  key    = "index.html"
  source = var.index_html
  etag   = filemd5(var.index_html)
  // see also: https://engineering.statefarm.com/blog/terraform-s3-upload-with-mime/
  content_type = "text/html"
  depends_on   = [aws_s3_bucket.b]
}
