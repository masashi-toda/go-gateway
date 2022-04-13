resource "aws_lb" "alb" {
  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  subnets            = var.private_subnets
  internal           = true

  security_groups = [
    aws_security_group.front_alb.id
  ]

  tags = var.tags
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.blue.id
    type             = "forward"
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

resource "aws_lb_target_group" "blue" {
  name                 = "${var.app_name}-blue"
  port                 = var.app_container_port
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

  tags = var.tags
}

resource "aws_lb_target_group" "green" {
  name                 = "${var.app_name}-green"
  port                 = var.app_container_port
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

  tags = var.tags
}
