resource "aws_ecs_cluster" "app" {
  name = "${var.container_name}-ecs"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.container_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  task_role_arn            = aws_iam_role.ecs_task_execution.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "${var.container_name}",
      image     = "${var.repository_url}",
      essential = true,
      portMappings = [
        {
          containerPort = var.container_port
        }
      ],
      environment = [
        for key in keys(var.environments) :
        {
          name  = key,
          value = lookup(var.environments, key)
        }
      ],
      logConfiguration = {
        logDriver = "awsfirelens"
      }
    },
    {
      name              = "log_router",
      image             = "${var.firelens_repository_url}:${var.firelens_tag}",
      essential         = true,
      memoryReservation = 50,
      environment = [
        {
          name  = "AWS_REGION",
          value = data.aws_region.current.name
        },
        {
          name  = "APP_LOG_GROUP",
          value = aws_cloudwatch_log_group.app.name
        },
        {
          name  = "APP_LOG_RETENTION_DAYS",
          value = "1"
        },
        {
          name  = "FIREHOSE_DELIVERY_STREAM",
          value = aws_kinesis_firehose_delivery_stream.firelens.name
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "${aws_cloudwatch_log_group.firehose.name}",
          awslogs-region        = "${data.aws_region.current.name}",
          awslogs-stream-prefix = "${var.container_name}-sidecar"
        }
      },
      firelensConfiguration = {
        type = "fluentbit",
        options = {
          config-file-type  = "file",
          config-file-value = "/fluent-bit/etc/extra.conf"
        }
      }
    }
  ])

  volume {
    name = "app-storage"
  }

  tags = var.tags
}

resource "aws_ecs_service" "app" {
  name            = "${var.container_name}-service"
  cluster         = aws_ecs_cluster.app.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.app.id
  desired_count   = var.container_desired_count

  network_configuration {
    subnets = var.subnets
    security_groups = [
      var.security_group_id,
      aws_security_group.ecs.id
    ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      network_configuration,
      load_balancer
    ]
  }
}

data "aws_region" "current" {}
