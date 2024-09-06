resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "OAC - ${aws_s3_bucket.static_website.bucket}"
  description                       = "Origin Access Controls for Static Website Hosting ${aws_s3_bucket.static_website.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


locals {
  s3_origin_id   = "${var.bucket_name}-origin"
  //s3_domain_name = "${var.bucket_name}.s3-website-${var.region}.amazonaws.com"
}

resource "aws_cloudfront_distribution" "static_website_cf" {
  enabled = true
  origin {
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
    domain_name              = aws_s3_bucket.static_website.bucket_regional_domain_name

  }
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["CA", "TN"]
    }
  }
  default_cache_behavior {

    target_origin_id = local.s3_origin_id
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Output CloudFront distribution domain name
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.static_website_cf.domain_name
}

/*
resource "terraform_data" "invalidate_cache" {

  triggers_replace = terraform_data.content_version.output

  provisioner "local-exec" {
    #https://developer.hashicorp.com/terraform/language/expressions/strings
    command = <<EOT
    aws cloudfront create-invalidation \
    --distribution-id ${aws_cloudfront_distribution.s3_distribution.id} \
    --path '/*'
    EOT 
  }
}
*/