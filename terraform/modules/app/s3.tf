resource "aws_s3_bucket" "app_logs" {
  bucket        = "${var.container_name}-app-logs"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
