################################################
# ECS Task
################################################
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.app_name}-ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_logs" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "firelens_task" {
  name = "${var.app_name}-firelensRolePolicy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "firehose:PutRecordBatch",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:PutRetentionPolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

################################################
# Kinesis Firehose
################################################
resource "aws_iam_role" "firehose_role" {
  name = "${var.app_name}-firehoseRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_role_policy" {
  name = "${var.app_name}-firehoseRolePolicy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "",
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource = [
          "${aws_s3_bucket.app-logs.arn}",
          "${aws_s3_bucket.app-logs.arn}/*"
        ]
      },
      {
        Sid    = "",
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents"
        ],
        Resource = [
          "${aws_cloudwatch_log_group.firehose.arn}:log-stream:*"
        ]
      }
    ]
  })
}

################################################
# CodeBuild
################################################
resource "aws_iam_role" "codebuild" {
  name = "${var.app_name}-codebuildAssumeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.app_name}-codebuildRolePolicy"
  policy = templatefile("${path.module}/templates/codebuild-policy.json",
    {
      aws_account_id      = data.aws_caller_identity.current.account_id
      codepipeline-bucket = aws_s3_bucket.codepipeline-artifacts.id
    }
  )
  role  = aws_iam_role.codebuild.id
}

################################################
# CodeDeploy
################################################
resource "aws_iam_role" "codedeploy" {
  name = "${var.app_name}-codedeployAssumeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy.name
}

################################################
# CodePipeline
################################################
resource "aws_iam_role" "codepipeline" {
  name = "${var.app_name}-codepipelineAssumeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${var.app_name}-codepipelineRolePolicy"
  policy = templatefile("${path.module}/templates/codepipeline-policy.json", {})
  role   = aws_iam_role.codepipeline.id
}
