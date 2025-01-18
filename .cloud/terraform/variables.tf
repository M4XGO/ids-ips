variable "function_name" {
  description = "Nom de la fonction Lambda"
  type        = string
  default     = "alerting_lambda"
}

variable "discord_webhook_url" {
  description = "URL du webhook Discord"
  type        = string
  default     = "https://discord.com/api/webhooks/1326151413184729178/A9U7SH65iEAU0eMqq5Cx7LxsSLuiF_dKpfZL7qHqGW-8vrXzQ34AUNvUuHVp-2EDr-Fr"
}

variable "source_code_path" {
  description = "Chemin vers le fichier zip du code source de la Lambda"
  type        = string
  default     = "./lambda_function.zip"
}

data "aws_region" "current" {
}

variable "shared_credential_file" {
  description = "Chemin vers le fichier de credentials partagés"
  type        = string
  default     = ".aws/credentials.ini"
  
}