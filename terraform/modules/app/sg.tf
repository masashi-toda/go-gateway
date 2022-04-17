resource "aws_security_group" "ecs" {
  name   = "${var.container_name}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = var.container_port
    to_port   = var.container_port
    protocol  = "tcp"

    security_groups = [
      var.security_group_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
