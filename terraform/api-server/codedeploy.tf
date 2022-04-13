resource "aws_codedeploy_app" "app" {
  name             = "${var.app_name}-deploy"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.app_name}-bluegreen"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
      "DEPLOYMENT_STOP_ON_ALARM"
    ]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.app.name
    service_name = aws_ecs_service.app.name
  }

  #  alarm_configuration {
  #    alarms                    = [aws_cloudwatch_metric_alarm.ecs-404s.alarm_name]
  #    enabled                   = true
  #    ignore_poll_alarm_failure = false
  #  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          aws_lb_listener.alb.arn
        ]
      }
      #      test_traffic_route {
      #        listener_arns = [aws_lb_listener.test.arn]
      #      }
      target_group {
        name = aws_lb_target_group.blue.name
      }
      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }

  lifecycle {
    ignore_changes = [
      blue_green_deployment_config
    ]
  }
}
