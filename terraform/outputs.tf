output "instance_public_ip" {
  description = "Public IP address of the Minecraft server."
  value       = aws_instance.minecraft_server.public_ip
}

output "minecraft_server_address" {
  description = "Address to use in Minecraft Java Edition."
  value       = "${aws_instance.minecraft_server.public_ip}:25565"
}

output "private_key_path" {
  description = "Path to the generated private key used by Ansible."
  value       = local_sensitive_file.private_key.filename
}