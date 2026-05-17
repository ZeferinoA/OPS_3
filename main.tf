terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.41.0"
    }
  }
  backend "s3" {
    bucket       = "araizaz-minecraft-backups"
    key          = "mc-world/key"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs AWS Academy restricts IAM roles needed for Flow Logs
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

#tfsec:ignore:aws-ec2-no-public-ip-subnet Required to connect to the Minecraft server without a Load Balancer
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

  #tfsec:ignore:aws-ec2-no-public-ingress-sgr Required for remote Ansible configuration
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #tfsec:ignore:aws-ec2-no-public-ingress-sgr Minecraft must be accessible to the public internet
  ingress {
    description = "Custom TCP"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #tfsec:ignore:aws-ec2-no-public-egress-sgr Required to pull Docker image
  egress {
    description = "Allow all outbound traffic for updates and Docker pulls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "minecraft-server-sg" }
}


resource "aws_instance" "minecraft_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.minecraft_public.id
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  iam_instance_profile   = "LabInstanceProfile"

  root_block_device {
    volume_size = 20 # Extra space for logs and world data
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "minecraft-server"
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for EC2 to boot..."
      sleep 90 
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${self.public_ip},' playbook.yml -u ubuntu --private-key ~/.ssh/cs312-key2.pem
    EOT
  }

}

#tfsec:ignore:aws-ecr-repository-customer-key AWS Academy prevents custom KMS key creation
#tfsec:ignore:aws-ecr-enforce-immutable-repository Mutability required to continually update the 'latest' tag via CI/CD
resource "aws_ecr_repository" "minecraft_repo" {
  name                 = "minecraft-server-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
