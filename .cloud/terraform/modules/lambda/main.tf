resource "aws_lambda_function" "my_lambda" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = var.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256(var.source_code_path)
  runtime         = "python3.8"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

resource "aws_cloudwatch_log_subscription_filter" "suricata_logs_to_lambda" {
  name            = "suricata_logs_to_lambda"
  log_group_name  = var.log_group_name    # ex: "/aws/suricata/logs"
  filter_pattern  = ""                   # déclenchement sur tous les logs
  destination_arn = aws_lambda_function.my_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = { Service = "lambda.amazonaws.com" },
        Effect   = "Allow",
        Sid      = ""
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "${var.function_name}_policy_attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}