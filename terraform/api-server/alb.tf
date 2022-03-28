resource "aws_lb" "front" {
  name               = "${var.app}-${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids

  security_groups = [
    aws_security_group.front_alb.id
  ]

  tags = {
    Owner = var.owner
  }
}

resource "aws_security_group" "front_alb" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = var.owner
  }
}

resource "aws_security_group" "api_server_web_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"

    security_groups = [
      aws_security_group.front_alb.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = var.owner
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.front.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.http.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "http" {
  name                 = "${var.app}-${var.environment}-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 5
    path                = "/health"
    interval            = 30
    timeout             = 10
  }

  tags = {
    Owner = var.owner
  }
}
