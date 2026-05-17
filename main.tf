terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.41.0"
    }
  }
  backend "s3" {
    bucket = "araizaz-minecraft-backups"
    key    = "mc-world/key"
    region = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "minecraft_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "minecraft-vpc" }
}

resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id
	
	tags = { Name = "minecraft-igw" }
}

resource "aws_subnet" "minecraft_public" {
  vpc_id                  = aws_vpc.minecraft_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

	tags = { Name = "minecraft-public-subnet" }
}

resource "aws_route_table" "minecraft_public_rt" {
  vpc_id = aws_vpc.minecraft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_igw.id
  }
	
	tags = { Name = "minecraft-public-rt" }

}

resource "aws_route_table_association" "minecraft_public_rta" {
  subnet_id      = aws_subnet.minecraft_public.id
  route_table_id = aws_route_table.minecraft_public_rt.id
}

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-server-sg"
  description = "Allow SSH and Minecraft traffic"
  vpc_id      = aws_vpc.minecraft_vpc.id

  ingress {
		description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
		description = "Custom TCP"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

	tags = { Name = "minecraft-server-sg" }
}


resource "aws_instance" "minecraft_server" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id = aws_subnet.minecraft_public.id
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  iam_instance_profile = "LabInstanceProfile"

  root_block_device {
    volume_size = 20 # Extra space for logs and world data
  }

  tags = {
    Name = "minecraft-server"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.public_ip}, playbook.yml"
  }

}

resource "aws_ecr_repository" "minecraft_repo" {
  name                 = "minecraft-server-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

