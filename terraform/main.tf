data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "tls_private_key" "minecraft_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.minecraft_key.private_key_pem
  filename        = "${path.module}/minecraft_key.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "minecraft_key" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.minecraft_key.public_key_openssh
}

resource "aws_security_group" "minecraft_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH and Minecraft traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH for Ansible"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Minecraft Java server"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = [var.allowed_minecraft_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "minecraft_server" {
  ami                         = "ami-05cf1e9f73fbad2e2"
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.minecraft_sg.id]
  key_name                    = aws_key_pair.minecraft_key.key_name
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-ec2"
  }
}