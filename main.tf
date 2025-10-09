provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "main" {
  cidr_block = var.aws_vpc_cidr
}

# resource "aws_instance" "web-deploy" {
#   ami = ""
#   instance_type = "t2.micro"

#   tags = {
#     Name = "web-deploy"
#   }
# }