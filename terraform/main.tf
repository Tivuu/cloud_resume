terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.2.0"
    }
  }

  # Remote state — shared between local and CI
  # The bucket was created manually (bootstrap step) and is never managed by Terraform itself
  backend "s3" {
    bucket = "mathproblemguy-tfstate"
    key    = "cloud_resume/terraform.tfstate"
    region = "us-east-1"
  }
}

# No hardcoded credential paths — the provider uses its default chain:
# 1. Environment variables (AWS_ACCESS_KEY_ID etc.) — used in CI via OIDC
# 2. ~/.aws/credentials — used locally
provider "aws" {
  region = "us-east-1"
}

# ── Resume site ───────────────────────────────────────────────────

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
  bucket     = aws_s3_bucket.mathproblemguy.id
  depends_on = [aws_s3_bucket_public_access_block.allow_public]

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

# ── Lovemap subdomain ─────────────────────────────────────────────

resource "aws_s3_bucket" "gnocchimap" {
  bucket = "gnocchimap.mathproblemguy.com"
}

resource "aws_s3_bucket_website_configuration" "subsite" {
  bucket = aws_s3_bucket.gnocchimap.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "sub_allow_public" {
  bucket = aws_s3_bucket.gnocchimap.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "sub_public_read" {
  bucket     = aws_s3_bucket.gnocchimap.id
  depends_on = [aws_s3_bucket_public_access_block.sub_allow_public]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.gnocchimap.arn}/*"
    }]
  })
}

# ── GitHub Actions OIDC ───────────────────────────────────────────
#
# This tells AWS to trust JWTs issued by GitHub's OIDC endpoint.
# When a workflow runs, GitHub mints a signed token; AWS verifies it
# against GitHub's public keys and issues a temporary STS credential.
# No long-lived keys are stored anywhere.

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  # "sts.amazonaws.com" is the audience GitHub Actions sets in its tokens
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC certificate thumbprint (stable — tied to their root CA)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# IAM role that GitHub Actions workflows will assume
resource "aws_iam_role" "github_actions" {
  name = "github-actions-deploy"

  # Trust policy: who can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_actions.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        # Only tokens from the Tivuu/cloud_resume repo on any ref
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:Tivuu/cloud_resume:*"
        }
        # Audience must match what we set above
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# What the role is allowed to do
resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # S3: read/write to both website buckets and the state bucket
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketWebsite",
          "s3:PutBucketWebsite",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::mathproblemguy.com",
          "arn:aws:s3:::mathproblemguy.com/*",
          "arn:aws:s3:::gnocchimap.mathproblemguy.com",
          "arn:aws:s3:::gnocchimap.mathproblemguy.com/*",
          "arn:aws:s3:::mathproblemguy-tfstate",
          "arn:aws:s3:::mathproblemguy-tfstate/*"
        ]
      },
      {
        # IAM: Terraform needs to read and manage the OIDC provider and role it created
        # (so it can update them without drift)
        Sid    = "IAMOIDCSelfManage"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}
