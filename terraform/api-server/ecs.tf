resource "aws_ecs_cluster" "app" {
  name = "${var.app_name}-ecs"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.app_container_cpu
  memory                   = var.app_container_memory
  task_role_arn            = aws_iam_role.ecs_task_execution.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}",
      image     = "${aws_ecr_repository.app.repository_url}",
      essential = true,
      portMappings = [
        {
          containerPort = var.app_container_port
        }
      ],
      environment = [
        for key in keys(var.app_environment) :
        {
          name  = key,
          value = lookup(var.app_environment, key)
        }
      ],
      logConfiguration = {
        logDriver = "awsfirelens"
      }
    },
    {
      name              = "log_router",
      image             = "${aws_ecr_repository.firelens.repository_url}:${var.firelens_tag}",
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
          awslogs-stream-prefix = "${var.app_name}-sidecar"
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
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.app.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.app.id
  desired_count   = "1"

  depends_on = [
    aws_lb_target_group.blue,
    aws_lb_target_group.green
  ]

  network_configuration {
    subnets = var.subnet_ids
    security_groups = [
      aws_security_group.front_alb.id,
      aws_security_group.ecs.id
    ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.app_name
    container_port   = var.app_container_port
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
