resource "aws_codedeploy_app" "app" {
  name             = "${var.name_prefix}-deploy"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.name_prefix}-bluegreen"
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
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
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
          var.lb_listener_arn
        ]
      }
      #      test_traffic_route {
      #        listener_arns = [aws_lb_listener.test.arn]
      #      }
      target_group {
        name = var.lb_target_group_1
      }
      target_group {
        name = var.lb_target_group_2
      }
    }
  }

  lifecycle {
    ignore_changes = [
      blue_green_deployment_config
    ]
  }
}
