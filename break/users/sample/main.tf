variable "user" {}
variable "username" {}
variable "password" {}
variable "pos_id" {}
variable "gmail_user" {}
variable "gmail_pass" {}
variable "to_email" {}
variable "subnets" {
  type = list(string)
}
variable "ecr_image_break_in" {}
variable "ecr_image_break_out" {}
variable "execution_role_arn" {}
variable "invoke_role_arn" {}
variable "cluster_arn" {}
variable "aws_region" {
  default = "us-east-1"                     # <==== YOU CAN CHANGE YOUR AWS REGION
}

# === break-in ECS Task ===
resource "aws_ecs_task_definition" "break_in" {
  family                   = "break-in-${var.user}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "break-in",
      image     = "${var.ecr_image_break_in}:latest",
      essential = true,
      environment = [
        { name = "USERNAME", value = var.username },
        { name = "PASSWORD", value = var.password },
        { name = "POS_ID", value = var.pos_id },
        { name = "GMAIL_USER", value = var.gmail_user },
        { name = "GMAIL_PASS", value = var.gmail_pass },
        { name = "GMAIL_SECOND_USER", value = var.to_email }
      ]
    }
  ])
}

# === break-in Schedule ===
resource "aws_scheduler_schedule" "break_in_schedule" {
  name = "run-break-in-${var.user}"

  schedule_expression          = "cron(15 16 * * ? *)"  # 4:15 PM ET
  schedule_expression_timezone = "America/New_York"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = var.cluster_arn
    role_arn = var.invoke_role_arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.break_in.arn
      launch_type          = "FARGATE"
      network_configuration {
        subnets          = var.subnets
        assign_public_ip = true
      }
    }

    input = jsonencode({
      containerOverrides = []
    })
  }
}

# === break-out ECS Task ===
resource "aws_ecs_task_definition" "break_out" {
  family                   = "break-out-${var.user}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "break-out",
      image     = "${var.ecr_image_break_out}:latest",
      essential = true,
      environment = [
        { name = "USERNAME", value = var.username },
        { name = "PASSWORD", value = var.password },
        { name = "POS_ID", value = var.pos_id },
        { name = "GMAIL_USER", value = var.gmail_user },
        { name = "GMAIL_PASS", value = var.gmail_pass },
        { name = "GMAIL_SECOND_USER", value = var.to_email }
      ]
    }
  ])
}

# === break-out Schedule ===
resource "aws_scheduler_schedule" "break_out_schedule" {
  name = "run-break-out-${var.user}"

  schedule_expression          = "cron(0 17 * * ? *)"  # 5:00 PM ET
  schedule_expression_timezone = "America/New_York"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = var.cluster_arn
    role_arn = var.invoke_role_arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.break_out.arn
      launch_type          = "FARGATE"
      network_configuration {
        subnets          = var.subnets
        assign_public_ip = true
      }
    }

    input = jsonencode({
      containerOverrides = []
    })
  }
}

