resource "aws_cloudwatch_log_group" "app_log_group" {
  name = "/ecs/logs/${var.app}-${var.environment}-ecs-group"
  tags = {
    Owner = var.owner
  }
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "firehose" {
  name = "/aws/kinesisfirehose/${var.app}-${var.environment}-firehose-logs"
  tags = {
    Owner = var.owner
  }
  retention_in_days = 1
}
