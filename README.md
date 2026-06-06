# Automated Minecraft Server on AWS

## Background

This project automates the provisioning and configuration of a Minecraft Java server on AWS. The goal is to avoid manual setup through the AWS Management Console and instead use Infrastructure as Code and configuration management.

This project uses:

- Terraform to provision AWS infrastructure
- Ansible to configure the EC2 instance
- systemd to manage the Minecraft server process
- nmap to verify that the Minecraft port is open

The Minecraft server is configured to automatically start when the EC2 instance reboots. It is also configured to shut down cleanly by sending the Minecraft `stop` command through systemd.

## Requirements

Install the following tools before running the project:

- Git
- Terraform
- AWS CLI
- Ansible
- nmap
- Minecraft Java Edition

You will also need AWS credentials from AWS Learner Lab or another AWS account.

## AWS Credentials

Before running the pipeline, configure AWS credentials.

For AWS Learner Lab, copy the temporary credentials and export them:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
export AWS_DEFAULT_REGION="us-east-1"