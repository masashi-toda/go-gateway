resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${var.container_name}-logs"
  retention_in_days = 1
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/firehose/${var.container_name}-logs"
  retention_in_days = 1
  tags              = var.tags
}
