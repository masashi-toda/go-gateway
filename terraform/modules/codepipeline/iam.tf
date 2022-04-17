################################################
# CodeBuild
################################################
resource "aws_iam_role" "codebuild" {
  name = "${var.name_prefix}-codebuildAssumeRole"
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
  name = "${var.name_prefix}-codebuildRolePolicy"
  policy = templatefile("${path.module}/templates/codebuild-policy.json",
    {
      aws_account_id      = data.aws_caller_identity.current.account_id
      codepipeline-bucket = aws_s3_bucket.codepipeline_artifacts.id
    }
  )
  role  = aws_iam_role.codebuild.id
}

################################################
# CodeDeploy
################################################
resource "aws_iam_role" "codedeploy" {
  name = "${var.name_prefix}-codedeployAssumeRole"
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
  name = "${var.name_prefix}-codepipelineAssumeRole"
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
  name = "${var.name_prefix}-codepipelineRolePolicy"
  policy = templatefile("${path.module}/templates/codepipeline-policy.json", {})
  role   = aws_iam_role.codepipeline.id
}
