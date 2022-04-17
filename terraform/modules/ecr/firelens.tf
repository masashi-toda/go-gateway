resource "aws_ecr_repository" "firelens" {
  name                 = var.firelens_repository_name
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
    command = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.firelens.repository_url}"
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/fluentbit"
    command     = "docker build -t ${var.firelens_repository_name}:${var.firelens_tag} ."
  }

  provisioner "local-exec" {
    command = "docker tag ${var.firelens_repository_name}:${var.firelens_tag} ${aws_ecr_repository.firelens.repository_url}:${var.firelens_tag}"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.firelens.repository_url}:${var.firelens_tag}"
  }
}

data "aws_region" "current" {}
