data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "app" {
  name = "${var.app}-${var.environment}-ecs"

  tags = {
    Owner = var.owner
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app}-${var.environment}",
      image     = "${aws_ecr_repository.app.repository_url}",
      essential = true,
      portMappings = [
        {
          containerPort = 8080
        }
      ],
      environment = [
        {
          name  = "AWS_REGION",
          value = "${data.aws_region.current.name}"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "${aws_cloudwatch_log_group.app_log_group.name}",
          awslogs-region        = "${data.aws_region.current.name}",
          awslogs-stream-prefix = "${var.group}-${var.app}-${var.environment}"
        }
      }
    }
  ])

  tags = {
    Owner = var.owner
  }
}

resource "aws_cloudwatch_log_group" "app_log_group" {
  name = "/ecs/logs/${var.app}-${var.environment}-ecs-group"
  tags = {
    Owner = var.owner
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.app}-${var.environment}-service"
  cluster         = aws_ecs_cluster.app.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.app.id
  desired_count   = "1"

  depends_on = [aws_alb_target_group.http]

  network_configuration {
    subnets = var.subnet_ids
    security_groups = [
      aws_security_group.front_alb.id,
      aws_security_group.api_server_web_sg.id
    ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.http.arn
    container_name   = "${var.app}-${var.environment}"
    container_port   = "8080"
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
