terraform {
  required_providers {
    aws = {
      version = "~>3.65"
    }
  }
}
provider "aws" {
  region = "eu-west-1"
}

# VARIABLES
variable "project_name" {
  default = "teamcity"
}

variable "cpu_reservation" {
  default = 0
}

variable "deploy_environment" {}
variable "cluster_name" {}
variable "alb_listener_arn" {}
variable "vpc_id" {}

variable "minimum_desired_count" {
  default = 1
}

variable "minimum_deployment_config_target" {
  default = 100
}

variable "maximum_deployment_config_target" {
  default = 200
}

# DATA
data "aws_ecs_cluster" "ecs" {
  cluster_name = var.cluster_name
}

data "aws_ecs_task_definition" "teamcity" {
  task_definition = aws_ecs_task_definition.teamcity.family
  depends_on      = [aws_ecs_task_definition.teamcity]
}

# ECS RESOURCES
resource "aws_ecs_task_definition" "teamcity" {
  depends_on    = [aws_iam_role.teamcity_role]
  family        = var.project_name
  task_role_arn = aws_iam_role.teamcity_role.arn

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.project_name}",
      "cpu": ${var.cpu_reservation},
      "memoryReservation": 500,
      "image": "jetbrains/teamcity-server",
      "essential": true,
      "portMappings": [{
        "containerPort": 8111
      }],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "ecs",
          "awslogs-region": "eu-west-1",
          "awslogs-stream-prefix": "${var.project_name}"
        }
      }
    }
  ]
DEFINITION
}

resource "aws_ecs_service" "teamcity" {
  name                               = var.project_name
  cluster                            = data.aws_ecs_cluster.ecs.id
  desired_count                      = var.minimum_desired_count
  iam_role                           = aws_iam_role.teamcity_service_role.arn
  depends_on                         = [aws_alb_listener_rule.teamcity_https]
  deployment_minimum_healthy_percent = var.minimum_deployment_config_target
  deployment_maximum_percent         = var.maximum_deployment_config_target

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.teamcity.family}:${max("${aws_ecs_task_definition.teamcity.revision}", "${data.aws_ecs_task_definition.teamcity.revision}")}"

  load_balancer {
    target_group_arn = aws_alb_target_group.teamcity.arn
    container_name   = var.project_name
    container_port   = 8111
  }

  # Spread 1 per instance first
  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}

resource "aws_alb_target_group" "teamcity" {
  name                 = "${var.project_name}-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 120

  tags = {
    Division    = "Bingo"
    Environment = "${var.deploy_environment}"
    Team-Role   = "Platform Infrastructure"
    Country     = "EU"
  }
}

resource "aws_alb_listener_rule" "teamcity_https" {
  listener_arn = var.alb_listener_arn
  priority     = 75

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.teamcity.arn
  }

  condition {
    path_pattern {
      values = ["/teamcity*"]
    }
  }
}
