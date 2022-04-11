resource "aws_codebuild_project" "app" {
  name                   = "${aws_ecs_cluster.app.name}-build"
  service_role           = aws_iam_role.codebuild.arn
  concurrent_build_limit = 1
  build_timeout          = "60"

  source {
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    }
    environment_variable {
      name  = "ECR_REPO_NAME"
      value = var.app_ecr_repo_name
    }
    environment_variable {
      name  = "ECS_TASK_DEFINITION_ARN"
      value = aws_ecs_task_definition.app.arn
    }
    environment_variable {
      name  = "ECS_CONTAINER_NAME"
      value = var.app_name
    }
    environment_variable {
      name  = "ECS_CONTAINER_PORT"
      value = var.app_container_port
    }
    dynamic "environment_variable" {
      for_each = var.app_environment
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  tags = var.tags
}
