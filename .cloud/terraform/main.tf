module "lambda" {
  source            = "./modules/lambda"
  function_name     = "suricata_alert_lambda"
  discord_webhook_url = "https://discord.com/api/webhooks/your_webhook_url"
  source_code_path  = "lambda_function.zip"
  log_group_name    = aws_cloudwatch_log_group.suricata_logs.name
}