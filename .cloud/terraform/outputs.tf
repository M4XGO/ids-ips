output "lambda_function_arn" {
  description = "ARN de la fonction Lambda"
  value       = module.lambda.lambda_function_arn
}

output "bastion_public_ip" {
  description = "L'adresse IP publique du bastion"
  value       = aws_instance.bastion.public_ip
}