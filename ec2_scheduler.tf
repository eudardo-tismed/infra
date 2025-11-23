# Arquivo ZIP da função Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_ec2_scheduler.py"
  output_path = "lambda_ec2_scheduler.zip"
}

# Função Lambda para controlar EC2
resource "aws_lambda_function" "ec2_scheduler" {
  filename         = "lambda_ec2_scheduler.zip"
  function_name    = "ec2-scheduler"
  role            = aws_iam_role.lambda_ec2_role.arn
  handler         = "lambda_ec2_scheduler.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 60

  tags = {
    Name        = "ec2-scheduler"
    provisioner = "terraform"
  }
}

# Role IAM para a função Lambda
resource "aws_iam_role" "lambda_ec2_role" {
  name = "lambda-ec2-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "lambda-ec2-scheduler-role"
    provisioner = "terraform"
  }
}

# Policy para permitir que a Lambda controle EC2
resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "lambda-ec2-scheduler-policy"
  description = "Policy para permitir start/stop de instâncias EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Anexar policy ao role
resource "aws_iam_role_policy_attachment" "lambda_ec2_policy_attachment" {
  role       = aws_iam_role.lambda_ec2_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

# EventBridge Rule para parar EC2 às 22h (horário UTC-3 = 01:00 UTC)
resource "aws_cloudwatch_event_rule" "stop_ec2_rule" {
  name                = "stop-ec2-22h"
  description         = "Parar EC2 às 22h (horário de Brasília)"
  schedule_expression = "cron(0 1 * * ? *)"  # 01:00 UTC = 22:00 BRT

  tags = {
    Name        = "stop-ec2-22h"
    provisioner = "terraform"
  }
}

# EventBridge Rule para iniciar EC2 às 6h (horário UTC-3 = 09:00 UTC)
resource "aws_cloudwatch_event_rule" "start_ec2_rule" {
  name                = "start-ec2-6h"
  description         = "Iniciar EC2 às 6h (horário de Brasília)"
  schedule_expression = "cron(0 9 * * ? *)"  # 09:00 UTC = 06:00 BRT

  tags = {
    Name        = "start-ec2-6h"
    provisioner = "terraform"
  }
}

# Target para o evento de parar EC2
resource "aws_cloudwatch_event_target" "stop_ec2_target" {
  rule      = aws_cloudwatch_event_rule.stop_ec2_rule.name
  target_id = "StopEC2Target"
  arn       = aws_lambda_function.ec2_scheduler.arn

  input = jsonencode({
    action      = "stop"
    instance_id = aws_instance.ec2_front.id
  })
}

# Target para o evento de iniciar EC2
resource "aws_cloudwatch_event_target" "start_ec2_target" {
  rule      = aws_cloudwatch_event_rule.start_ec2_rule.name
  target_id = "StartEC2Target"
  arn       = aws_lambda_function.ec2_scheduler.arn

  input = jsonencode({
    action      = "start"
    instance_id = aws_instance.ec2_front.id
  })
}

# Permissão para EventBridge invocar a função Lambda (stop)
resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_ec2_rule.arn
}

# Permissão para EventBridge invocar a função Lambda (start)
resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_ec2_rule.arn
}

# Output com informações úteis
output "lambda_function_name" {
  description = "Nome da função Lambda"
  value       = aws_lambda_function.ec2_scheduler.function_name
}

output "ec2_instance_id" {
  description = "ID da instância EC2 que será controlada"
  value       = aws_instance.ec2_front.id
}

output "stop_schedule" {
  description = "Horário de parada (22h BRT)"
  value       = "22:00 (horário de Brasília)"
}

output "start_schedule" {
  description = "Horário de início (6h BRT)"
  value       = "06:00 (horário de Brasília)"
}