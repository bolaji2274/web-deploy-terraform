provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web-deploy" {
  ami = ""
  instance_type = "t2.micro"

  tags = {
    Name = "web-deploy"
  }
}