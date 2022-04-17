resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.name_prefix}-logs"
  retention_in_days = 1
  tags              = var.tags
}
