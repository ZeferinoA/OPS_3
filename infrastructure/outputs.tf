output "instance_public_ip" {
  value       = aws_instance.minecraft_server.public_ip
  description = "Public IP to connect to via SSH and Minecraft client"
}

output "ecr_repository_url" {
  description = "ECR repository URL: use this in the GitHub Actions workflow"
  value       = aws_ecr_repository.minecraft_repo.repository_url
}

