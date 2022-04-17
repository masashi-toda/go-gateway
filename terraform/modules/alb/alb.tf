resource "aws_lb" "alb" {
  name               = "${var.name_prefix}-alb"
  load_balancer_type = "application"
  subnets            = var.subnets
  internal           = var.internal

  security_groups = [
    aws_security_group.alb.id
  ]

  tags = var.tags
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  depends_on = [
    aws_lb_target_group.blue,
    aws_lb_target_group.green
  ]

  default_action {
    target_group_arn = aws_lb_target_group.blue.arn
    type             = "forward"
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

resource "aws_lb_target_group" "blue" {
  name                 = "${var.name_prefix}-blue"
  port                 = var.target_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 5
    path                = var.health_check_path
    interval            = 30
    timeout             = 10
  }

  tags = var.tags
}

resource "aws_lb_target_group" "green" {
  name                 = "${var.name_prefix}-green"
  port                 = var.target_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 5
    path                = var.health_check_path
    interval            = 30
    timeout             = 10
  }

  tags = var.tags
}
