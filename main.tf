provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "main" {
  cidr_block = var.aws_vpc_cidr
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
  tags = {
    Name = "three-tier-main-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "three-tier-main-igw"
  }
}
resource "aws_subnet" "web_public_az1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "web_public_az1"
  }
  # depends_on = [ 
  #   aws_vpc.main
  #   ]
}
resource "aws_subnet" "app_private_az1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "app_private_az1"
  }
}

resource "aws_subnet" "db_private_az1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "db_private_az1"
  }
  # depends_on = [ 
  #   aws_vpc.public_subnet
  #   ]
}

resource "aws_subnet" "web_public_az2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "web_public_az2"
  }
}

resource "aws_subnet" "app_private_az2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "app_private_az2"
  }
}

resource "aws_subnet" "db_private_az2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "db_private_az2"
  }
}

resource "aws_eip" "nat_az1" {
  domain = "vpc"
  tags = {
    Name = "nat_eip_az1"
  }
}

resource "aws_eip" "nat_az2" {
  domain = "vpc"
  tags = {
    Name = "nat_eip_az2"
  }
  
}

resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id = aws_subnet.web_public_az1.id
  tags = {
    Name = "nat_gateway_az1"
  }
  depends_on = [ aws_internet_gateway.main ]
}

resource "aws_nat_gateway" "az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id = aws_subnet.web_public_az2.id
  tags = {
    Name = "nat_gateway_az2"
  }
  depends_on = [ aws_internet_gateway.main ]
  
}

# Route Tables
# Public Route Table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "public-rt"
  }
  # depends_on = [ 
  #   aws_internet_gateway.main
  #   ]
}

# Private Route Table for az1
resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.az1.id
  }
  
  tags = {
    Name = "private-rt-az1"
  }
  # depends_on = [ 
  #   aws_nat_gateway.az1
  #   ]
}

# Private Route Table for az2
resource "aws_route_table" "private_az2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.az2.id
  }
  
  tags = {
    Name = "private-rt-az2"
  }
  # depends_on = [ 
  #   aws_nat_gateway.az2
  #   ]
  }

  # Route table association

  resource "aws_route_table_association" "web_public_az1" {
    subnet_id = aws_subnet.web_public_az1.id
    route_table_id = aws_route_table.public.id
  }

  resource "aws_route_table_association" "web_public_az2" {
    subnet_id = aws_subnet.web_public_az2.id
    route_table_id = aws_route_table.public.id
  }

  resource "aws_route_table_association" "app_private_az1" {
    subnet_id = aws_subnet.app_private_az1.id
    route_table_id = aws_route_table.private_az1.id
  }

  resource "aws_route_table_association" "db_private_az1" {
    subnet_id = aws_subnet.db_private_az1.id
    route_table_id = aws_route_table.private_az1.id
  }

  resource "aws_route_table_association" "app_private_az2" {
    subnet_id = aws_subnet.app_private_az2.id
    route_table_id = aws_route_table.private_az2.id
  }
  resource "aws_route_table_association" "db_private_az2" {
    subnet_id = aws_subnet.db_private_az2.id
    route_table_id = aws_route_table.private_az2.id
  }

# Security Groups
# web tier Security Group

resource "aws_security_group" "web_tier" {
  name = "web_tier_sg"
  description = "security group for web tier"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress = {
  #   from_port = 22
  #   to_port = 22
  #   protocol = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_tier_sg"
  }

}

resource "aws_security_group" "app_tier_sg" {
  name = "app_tier_sg"
  description = "security group for app tier"
  vpc_id = aws_vpc.main.id
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.web_tier.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Name = "app_tier_sg"
  }
}

# DB Tier security group

resource "aws_security_group" "db_tier_sg" {
  name = "db_tier_sg"
  description = "security group for db tier"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.app_tier_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Name = "db_tier_sg"
  }

}

# S3 bucket for content delivery
resource "aws_s3_bucket" "app_content" {
  bucket = "three-tier-app-content-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "app_content_bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket_public_access_block" "app_content" {
  bucket = aws_s3_bucket.app_content.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false  
}

# IAM Role for EC2 to access the S3

resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsondecode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        # "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "ec2_s3_policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsondecode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_content.arn,
          "${aws_s3_bucket.app_content.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_role.name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn-ami-hvm-*-x86_64-ebs"]
  }
  
  # filter {
  #   name = "root-device-type"
  # }
}

