resource "aws_lb" "nlb" {
  name               = "${var.app_name}-nlb"
  load_balancer_type = "network"
  subnets            = var.public_subnets
  internal           = false

  tags = var.tags
}

resource "aws_lb_listener" "nlb" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.nlb.id
    type             = "forward"
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

resource "aws_lb_target_group" "nlb" {
  name        = "${var.app_name}-nlb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"
  deregistration_delay = 60

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 5
    path                = "/health"
    interval            = 30
  }

  tags = var.tags
}

/*
resource "aws_lb_target_group_attachment" "tg_nlb_attachment" {
  target_group_arn = aws_lb_target_group.nlb.arn
  target_id        = aws_lb.alb.arn
  port             = 80
}
*/
