provider "aws" {
  region = "us-west-2"
  profile = "maxime-test-esgi"
  #  shared_config_files      = ["/Users/tf_user/.aws/conf"]
  shared_credentials_files = [".aws/credentials.ini"]
  
}