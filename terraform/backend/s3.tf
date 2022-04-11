resource "aws_s3_bucket" "terraform-state" {
  bucket = var.s3_bucket
  acl    = "private"

  lifecycle {
    #prevent_destroy = true
  }

  tags = {
    Terraform = "true"
    Name      = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform-state" {
  bucket = aws_s3_bucket.terraform-state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
