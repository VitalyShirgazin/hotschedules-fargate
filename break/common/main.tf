provider "aws" {
  region = "us-east-1"
}

# === ECR Repositories ===
resource "aws_ecr_repository" "break_in" {
  name                  = "break-in"
  image_tag_mutability = "MUTABLE"
  force_delete          = true
}

resource "aws_ecr_repository" "break_out" {
  name                  = "break-out"
  image_tag_mutability = "MUTABLE"
  force_delete          = true
}

# === ECS Cluster ===
resource "aws_ecs_cluster" "main" {
  name = "break-cluster"
}

# === IAM Role for ECS Task Execution ===
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# === IAM Role for EventBridge Scheduler to Invoke ECS Tasks ===
resource "aws_iam_role" "events_invoke_ecs" {
  name = "eventbridge_invoke_ecs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "scheduler.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "events_policy" {
  role = aws_iam_role.events_invoke_ecs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition"
        ],
        Resource = [
          "arn:aws:ecs:us-east-1:CHANGE_ME:task-definition/break-in*", # <====== CHANGE TO YOUR AWS ACCOUNT ID NUMBER
          "arn:aws:ecs:us-east-1:CHANGE_ME:task-definition/break-out*" # <====== CHANGE TO YOUR AWS ACCOUNT ID NUMBER
        ]
      },
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = aws_iam_role.ecs_task_execution_role.arn
      }
    ]
  })
}

# === Outputs ===
output "ecr_repository_url_break_in" {
  value = aws_ecr_repository.break_in.repository_url
}

output "ecr_repository_url_break_out" {
  value = aws_ecr_repository.break_out.repository_url
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "invoke_role_arn" {
  value = aws_iam_role.events_invoke_ecs.arn
}
