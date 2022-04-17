output "repository_name" {
  value =  "${aws_ecr_repository.main.name}"
}

output "repository_url" {
  value =  "${aws_ecr_repository.main.repository_url}"
}

output "firelens_repository_url" {
  value =  "${aws_ecr_repository.firelens.repository_url}"
}
