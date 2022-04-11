resource "aws_codecommit_repository" "app" {
  repository_name = var.app_name
  tags = var.tags
}
