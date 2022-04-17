resource "aws_codecommit_repository" "app" {
  repository_name = var.git_repository_name
  tags = var.tags
}
