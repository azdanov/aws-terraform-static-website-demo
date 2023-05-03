terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.63"
    }
  }
  backend "s3" {
    bucket         = "azdanov-aws-static-website-demo-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "azdanov-aws-static-website-demo-terraform-lock-table"
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the website, e.g. example.com. Must already be registered with Route53."
}

locals {
  origin_id = "${var.domain_name}-${sha1(var.domain_name)}"
}

# Route53 zone
data "aws_route53_zone" "zone" {
  name = var.domain_name
}


# S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = substr(local.origin_id, 0, 63)

  tags = {
    Name = var.domain_name
  }
}

resource "aws_s3_bucket_public_access_block" "access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ACM certificate
resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_record" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_record : record.fqdn]
}


# CloudFront distribution
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.domain_name} access control"
  description                       = "Cloudfront access control for the ${var.domain_name} distribution."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "cache_policy" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "response_headers_policy" {
  name = "Managed-SecurityHeadersPolicy"
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2and3"
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false
  aliases             = [var.domain_name]

  origin {
    domain_name              = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.origin_id
  }

  custom_error_response {
    error_code         = "403"
    response_code      = "200"
    response_page_path = "/index.html"
  }

  default_cache_behavior {
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = local.origin_id
    cache_policy_id            = data.aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.origin_request_policy.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.response_headers_policy.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.certificate.arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_record" "cloudfront_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
  }
}

data "aws_iam_policy_document" "document" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.document.json
}
