output "lambda_function_arn" {
  description = "ARN de la fonction Lambda"
  value       = aws_lambda_function.my_lambda.arn
}