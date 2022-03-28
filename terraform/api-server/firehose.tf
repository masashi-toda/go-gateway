resource "aws_kinesis_firehose_delivery_stream" "firelens" {
  name        = "${var.app}-${var.environment}-deliverystream"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.app_logs.arn

    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = aws_cloudwatch_log_group.firehose.id
      log_stream_name = "firehose_error"
    }
  }
}

resource "aws_s3_bucket" "app_logs" {
  bucket = "${var.app}-${var.environment}-deliverylog"
}
