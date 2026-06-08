# Minecraft Infrastructure
## File Map
- `/infrastructure/`
  - Terraform code used to provision the AWS EC2 instance, ECR, and S3 buckets.
- `/ansible/`
  - Ansible roles and playbooks used to configure the host OS and install k3s.
- `/manifests/`
  - `minecraft.yaml`: Minecraft Deployment, Service, and HostPath storage setup.
- `/monitoring/`
  - `monitoring-values.yaml`: Helm configuration for the Prometheus/Grafana stack.
  - `minecraft-servicemonitor.yaml`: Target discovery logic for the exporter.
  - `minecraft-alerts.yaml`: Prometheus alert rule definitions.