resource "aws_dynamodb_table" "terraform-state-lock" {
  name           = var.dynamodb_table
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    #prevent_destroy = true
  }

  tags = {
    Terraform = "true"
    Name      = "terraform"
  }
}
