provider "aws" {
  region                   = "eu-west-3"
  profile                  = "maxime-test-esgi"
  shared_credentials_files = [var.shared_credential_file]
}