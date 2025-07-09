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
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.mathproblemguy.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.mathproblemguy.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.mathproblemguy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.mathproblemguy.arn}/*"
    }]
  })
}

resource "aws_s3_bucket" "gnocchimapmathproblemguy" {
  bucket = "gnocchimap.mathproblemguy.com"
}

resource "aws_s3_bucket_website_configuration" "subsite" {
  bucket = aws_s3_bucket.gnocchimapmathproblemguy.id

  index_document {
    suffix = "/build/index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "sub_allow_public" {
  bucket = aws_s3_bucket.gnocchimapmathproblemguy.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "sub_public_read" {
  bucket = aws_s3_bucket.gnocchimapmathproblemguy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.gnocchimapmathproblemguy.arn}/*"
    }]
  })
}

