terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.2.0"
    }
  }
}

provider "aws" {
      region = "us-east-1"
      shared_config_files      = ["/home/ryab/.aws/config"]
      shared_credentials_files = ["/home/ryab/.aws/credentials"]
}

resource "aws_s3_bucket" "mathproblemguy" {
  bucket = "mathproblemguy.com"

  tags = {
    Name        = "mathproblemguy.com"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "wwwmathproblemguy" {
  bucket = "www.mathproblemguy.com"
}

resource "aws_s3_bucket_website_configuration" "mathproblemguy" {
  bucket = aws_s3_bucket.mathproblemguy.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.mathproblemguy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          "Service" : "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.mathproblemguy.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.mathproblemguy.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_control" "mathproblemguy_oac" {
  name                              = "mathproblemguy-oac"
  description                       = "OAC for mathproblemguy CloudFront to access S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "mathproblemguy" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.mathproblemguy.bucket_regional_domain_name
    origin_id   = "S3-mathproblemguy"

    origin_access_control_id = aws_cloudfront_origin_access_control.mathproblemguy_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-mathproblemguy"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "Production"
  }
}
