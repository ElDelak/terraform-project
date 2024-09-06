# Create an S3 bucket for hosting static website files
resource "aws_s3_bucket" "static_website" {
  bucket = var.bucket_name
  tags   = { Name = "iot" }

  provisioner "local-exec" {
    command = "aws s3 sync ./tools/build/ s3://${aws_s3_bucket.static_website.bucket}"
  }
}

resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_website.bucket
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = {
      "Sid"    = "AllowCloudFrontServicePrincipalReadOnly",
      "Effect" = "Allow",
      "Principal" = {
        "Service" = "cloudfront.amazonaws.com"
      },
      "Action"   = "s3:GetObject",
      "Resource" = "arn:aws:s3:::${aws_s3_bucket.static_website.id}/*",
      "Condition" = {
        "StringEquals" = {
          "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.static_website_cf.id}"
        }
      }
    }
  })
}