resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}-app"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

# Minimal execution role for ECS tasks:
# - pull from ECR
# - write logs to CloudWatch
resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "task_execution_policy" {
  name = "${var.project_name}-ecs-exec-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = aws_cloudwatch_log_group.app.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution_policy.arn
}

# Task role (least-privilege). App doesn't call AWS in this challenge,
# so keep permissions empty by default.
resource "aws_iam_role" "task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow inbound from ALB only (least-privilege)"
  vpc_id      = var.vpc_id

  ingress {
    description      = "App port from ALB"
    from_port        = var.container_port
    to_port          = var.container_port
    protocol         = "tcp"
    security_groups  = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = "${var.ecr_repository_url}:${var.ecr_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      environment = [
        for k, v in var.app_environment : {
          name  = k
          value = v
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# NOTE: Service uses ALB target group created in ALB module via attachment.
locals {
  # ALB target group ARN looks like:
  # arn:aws:elasticloadbalancing:REGION:ACCOUNT:targetgroup/TG_NAME/TG_ID
  # CloudWatch metric dimensions for UnHealthyHostCount expect the part after "targetgroup/"
  alb_target_group_dimension = (
    length(split("targetgroup/", var.alb_target_group_arn)) > 1
    ? split("targetgroup/", var.alb_target_group_arn)[1]
    : var.alb_target_group_arn
  )
}

resource "aws_ecs_service" "app" {
  name              = "${var.project_name}-service"
  cluster           = aws_ecs_cluster.this.id
  desired_count     = var.desired_count
  launch_type       = "FARGATE"
  platform_version  = "1.4.0"

  task_definition = aws_ecs_task_definition.app.arn

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "${var.project_name}-container"
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  # Deployment best practices
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  # Force ECS to replace tasks on image tag changes
  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_ecs_task_definition.app
  ]
}

# Alarm on ALB target group unhealthy hosts to catch availability regressions.
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1

  dimensions = {
    TargetGroup = local.alb_target_group_dimension
  }

  alarm_description = "Triggers when at least one unhealthy host is detected for the target group."
  treat_missing_data = "notBreaching"

  lifecycle {
    prevent_destroy = false
  }
}

locals {
  ecs_alarm_enabled = var.enable_ecs_resource_alarms
}

# CPU alarm (optional, enabled by default)
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count = local.ecs_alarm_enabled ? 1 : 0

  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_description = "Triggers when ECS CPU utilization is high for the service."
  treat_missing_data = "notBreaching"

  lifecycle {
    prevent_destroy = false
  }
}

# Memory alarm (optional, enabled by default)
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  count = local.ecs_alarm_enabled ? 1 : 0

  alarm_name          = "${var.project_name}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_description = "Triggers when ECS memory utilization is high for the service."
  treat_missing_data = "notBreaching"

  lifecycle {
    prevent_destroy = false
  }
}
