terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Use your existing S3 bucket
resource "aws_s3_bucket" "portfolio" {
  bucket = var.bucket_name
}

# Upload all website files (HTML, CSS, PDF, etc.)
resource "aws_s3_object" "website_files" {
  for_each = fileset("website", "**")

  bucket       = aws_s3_bucket.portfolio.id
  key          = each.value
  source       = "website/${each.value}"
  content_type = lookup(var.mime_types, regex("\\.[^.]+$", each.value), "text/plain")
}
