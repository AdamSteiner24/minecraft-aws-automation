variable "project_name" {
  description = "Name used for tagging AWS resources."
  type        = string
  default     = "minecraft-server"
}

variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the Minecraft server."
  type        = string
  default     = "t3.small"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to connect over SSH for Ansible."
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_minecraft_cidr" {
  description = "CIDR block allowed to connect to Minecraft."
  type        = string
  default     = "0.0.0.0/0"
}