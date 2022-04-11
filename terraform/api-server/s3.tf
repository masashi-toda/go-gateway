resource "aws_s3_bucket" "app-logs" {
  bucket        = "${var.app_name}-app-logs"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "app-logs" {
  bucket = aws_s3_bucket.app-logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "codepipeline-artifacts" {
  bucket        = "${var.app_name}-codepipeline-artifacts"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "codepipeline-artifacts" {
  bucket = aws_s3_bucket.codepipeline-artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
