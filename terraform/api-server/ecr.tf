resource "aws_ecr_repository" "app" {
  name                 = var.app_ecr_name
  image_tag_mutability = "MUTABLE"

  lifecycle {
    create_before_destroy = true
  }
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "app" {
  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid       = "api-server-ecr",
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:PutLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:StartLifecyclePolicyPreview"
        ]
      }
    ]
  })

  repository = aws_ecr_repository.app.name
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_ecr_repository" "firelens" {
  name                 = var.firelens_repo_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "fluentbit" {
  triggers = {
    ecr_repo_create = aws_ecr_repository.firelens.arn
  }

  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.firelens.repository_url}"
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/fluentbit"
    command     = "docker build -t ${var.firelens_repo_name}:${var.firelens_tag} ."
  }

  provisioner "local-exec" {
    command = "docker tag ${var.firelens_repo_name}:${var.firelens_tag} ${aws_ecr_repository.firelens.repository_url}:${var.firelens_tag}"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.firelens.repository_url}:${var.firelens_tag}"
  }
}
