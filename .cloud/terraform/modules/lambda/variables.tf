variable "function_name" {
  description = "Nom de la fonction Lambda"
  type        = string
}

variable "discord_webhook_url" {
  description = "URL du webhook Discord"
  type        = string
}

variable "source_code_path" {
  description = "Chemin vers le fichier zip du code source de la Lambda"
  type        = string
}

variable "log_group_name" {
  description = "Nom du groupe de logs CloudWatch"
  type        = string
}

variable "region" {
  default = "eu-west-3"
  description = "value of the region"
  type = string
}

data "aws_caller_identity" "current" {}