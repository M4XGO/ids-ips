module "lambda" {
  source              = "./modules/lambda"
  function_name       = "suricata_alert_lambda"
  discord_webhook_url = "https://discord.com/api/webhooks/1326151413184729178/A9U7SH65iEAU0eMqq5Cx7LxsSLuiF_dKpfZL7qHqGW-8vrXzQ34AUNvUuHVp-2EDr-Fr"
  source_code_path    = "lambda_function.zip"
  log_group_name      = aws_cloudwatch_log_group.suricata_logs.name
}