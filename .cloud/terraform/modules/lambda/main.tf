resource "aws_lambda_function" "my_lambda" {
  function_name = var.function_name
  runtime       = "python3.8"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

resource "aws_cloudwatch_log_subscription_filter" "suricata_logs_to_lambda" {
  name            = "suricata_logs_to_lambda"
  log_group_name  = var.log_group_name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.my_lambda.arn
  role_arn        = aws_iam_role.lambda_role.arn

}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "${var.function_name}_policy_attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}