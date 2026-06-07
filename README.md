# Automated Minecraft Server on AWS

## Project Overview

This project automates the provisioning, configuration, and verification of a Minecraft Java server on AWS. The goal is to create and configure the server without manually using the AWS Management Console.

The project uses Terraform to provision AWS infrastructure, Ansible to configure the EC2 instance, systemd to manage the Minecraft server process, and nmap to verify that the Minecraft server port is open.

The final result is an AWS EC2 instance running a Minecraft Java server on TCP port `25565`.

---

## Requirements

### Required Tools

Before running this project, install the following tools:

| Tool                   | Purpose                            |
| ---------------------- | ---------------------------------- |
| Git                    | Clone and manage the repository    |
| AWS CLI                | Authenticate and interact with AWS |
| Terraform              | Provision AWS infrastructure       |
| Ansible                | Configure the EC2 instance         |
| nmap                   | Verify the Minecraft server port   |
| Minecraft Java Edition | Connect to the server              |

### Tested Environment

This project was tested using:

| Item             | Version / Setting                 |
| ---------------- | --------------------------------- |
| Operating System | Kali Linux through WSL on Windows |
| AWS Region       | `us-east-1`                       |
| Terraform        | `>= 1.5.0`                        |
| AWS Provider     | `~> 5.0`                          |
| EC2 AMI          | Ubuntu Server 24.04 LTS           |
| Instance Type    | `t3.small`                        |
| Minecraft Port   | TCP `25565`                       |

Windows users should run this project from WSL instead of PowerShell because Ansible and SSH key permissions work better in a Linux environment.

---

## AWS Credentials

This project requires AWS CLI credentials. If using AWS Learner Lab, start the lab first, then copy the AWS CLI credentials from the lab page.

Export the credentials in WSL:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
export AWS_DEFAULT_REGION="us-east-1"
```

Verify that AWS CLI is working:

```bash
aws sts get-caller-identity
```

This should return AWS account and role information.

Do not commit AWS credentials to GitHub.

---

## Pipeline Overview

The deployment pipeline has several stages:

```text
Local Machine / WSL
        |
        v
Configure AWS CLI credentials
        |
        v
Run the pipeline script
        |
        v
Terraform provisions AWS infrastructure
        |
        v
Terraform outputs the EC2 public IP address
        |
        v
The script creates the Ansible inventory file
        |
        v
Ansible configures the Minecraft server
        |
        v
systemd starts and manages the Minecraft service
        |
        v
nmap verifies TCP port 25565
        |
        v
User connects through Minecraft Java Edition
```

---

## Repository Structure

```text
minecraft-aws-automation/
├── README.md
├── .gitignore
├── terraform/
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   └── outputs.tf
├── ansible/
│   ├── inventory.ini
│   ├── setup_minecraft.yml
│   └── templates/
│       ├── minecraft.service.j2
│       ├── start_minecraft.sh.j2
│       └── stop_minecraft.sh.j2
└── scripts/
    ├── run_pipeline.sh
    ├── nmap_check.sh
    └── destroy.sh
```

---

## What Terraform Creates

Terraform provisions the AWS infrastructure needed to run the Minecraft server.

Terraform creates:

* EC2 instance
* Security group
* AWS key pair
* Local private key file
* Public IP output

The security group allows the following inbound traffic:

| Port  | Protocol | Purpose                       |
| ----- | -------- | ----------------------------- |
| 22    | TCP      | SSH access for Ansible        |
| 25565 | TCP      | Minecraft Java server traffic |

The EC2 instance uses Ubuntu Server 24.04 LTS and is configured with IMDSv2 required.

---

## What Ansible Configures

After Terraform creates the EC2 instance, Ansible connects to the instance and configures the Minecraft server.

The Ansible playbook performs these tasks:

1. Updates the package cache.
2. Installs Java and required packages.
3. Creates a dedicated `minecraft` user and group.
4. Creates the `/opt/minecraft` server directory.
5. Downloads the Minecraft server `.jar`.
6. Accepts the Minecraft EULA.
7. Creates the `server.properties` file.
8. Installs Minecraft start and stop scripts.
9. Installs a `systemd` service file.
10. Unmasks the Minecraft service if needed.
11. Enables and starts the Minecraft service.

The Minecraft server is managed by systemd so that it can automatically start again after the EC2 instance reboots.

---

## How to Run the Project

### 1. Clone the Repository

```bash
git clone https://github.com/adamsteiner24/minecraft-aws-automation.git
cd minecraft-aws-automation
```

### 2. Configure AWS Credentials

Export AWS Learner Lab credentials:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
export AWS_DEFAULT_REGION="us-east-1"
```

Verify AWS access:

```bash
aws sts get-caller-identity
```

### 3. Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### 4. Run the Full Pipeline

```bash
./scripts/run_pipeline.sh
```

This script does the following:

1. Runs `terraform init`.
2. Runs `terraform apply`.
3. Gets the EC2 public IP from Terraform output.
4. Copies the private key into the WSL SSH directory.
5. Updates the Ansible inventory file.
6. Runs the Ansible playbook.
7. Prints the Minecraft server address.

A successful run should end with an Ansible recap similar to this:

```text
failed=0
unreachable=0
```

---

## Verify the Minecraft Server

After the pipeline finishes, verify that the Minecraft service is running:

```bash
ansible -i ansible/inventory.ini minecraft -b -m shell -a "systemctl status minecraft --no-pager"
```

The output should show:

```text
Active: active (running)
```

Check that the server is listening on port `25565`:

```bash
ansible -i ansible/inventory.ini minecraft -b -m shell -a "ss -tulpen | grep 25565 || true"
```

Then run the required nmap command:

```bash
nmap -sV -Pn -p T:25565 <instance_public_ip>
```

Example:

```bash
nmap -sV -Pn -p T:25565 107.22.16.179
```

A successful result should show:

```text
25565/tcp open minecraft
```

You can also use the included script:

```bash
./scripts/nmap_check.sh
```

---

## Connect to the Minecraft Server

Open Minecraft Java Edition.

1. Click **Multiplayer**.
2. Click **Add Server**.
3. Enter the server address from Terraform output.
4. Join the server.

Example server address:

```text
107.22.16.179:25565
```

The Minecraft client version should match the server version downloaded by the Ansible playbook.

---

## Reboot and Auto-Start Test

The Minecraft server is configured as a systemd service, so it should start automatically after the EC2 instance reboots.

To test this without manually SSHing into the instance, run:

```bash
ansible -i ansible/inventory.ini minecraft -b -m reboot
```

After the instance comes back online, verify that the service is enabled and active:

```bash
ansible -i ansible/inventory.ini minecraft -b -m shell -a "systemctl is-enabled minecraft"
ansible -i ansible/inventory.ini minecraft -b -m shell -a "systemctl is-active minecraft"
```

Expected output:

```text
enabled
active
```

Then verify the port again:

```bash
./scripts/nmap_check.sh
```

---

## Destroy the Infrastructure

To remove the AWS resources created by Terraform, run:

```bash
./scripts/destroy.sh
```

This script runs:

```bash
terraform destroy -auto-approve
```

Destroying resources is important to avoid unnecessary AWS Learner Lab usage.

---

## Troubleshooting

### Private Key Permission Error

If Ansible gives an error like this:

```text
WARNING: UNPROTECTED PRIVATE KEY FILE
bad permissions
```

copy the key into the WSL SSH directory and lock down the permissions:

```bash
mkdir -p ~/.ssh
cp terraform/minecraft_key.pem ~/.ssh/minecraft_key.pem
chmod 600 ~/.ssh/minecraft_key.pem
```

The pipeline script is designed to do this automatically.

### Port 25565 Shows Closed

If nmap shows this:

```text
25565/tcp closed minecraft
```

check the Minecraft service logs:

```bash
ansible -i ansible/inventory.ini minecraft -b -m shell -a "journalctl -u minecraft --no-pager -n 80"
```

A common cause is a Java version mismatch. The Minecraft server jar must be compatible with the installed Java version.

### AWS Learner Lab Credentials Expired

If AWS commands fail, restart the AWS Learner Lab and export fresh credentials.

Then verify the credentials again:

```bash
aws sts get-caller-identity
```

### Duplicate Key Pair Error

If Terraform gives an error saying the key pair already exists, delete the old key pair:

```bash
aws ec2 delete-key-pair --key-name minecraft-server-key --region us-east-1
```

Then rerun the pipeline.

---

## Notes

This project does not use the AWS Management Console during the deployment process. AWS resources are created through Terraform and AWS CLI credentials. Server configuration is completed through Ansible.

The EC2 instance is not manually configured through SSH. Ansible uses SSH automatically as part of the automated configuration pipeline.

---

## Resources Used

* Terraform Documentation: https://developer.hashicorp.com/terraform/docs
* Terraform AWS Provider Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
* AWS CLI Documentation: https://docs.aws.amazon.com/cli/
* AWS EC2 Security Groups Documentation: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html
* AWS EC2 Instance Metadata Documentation: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html
* Ansible Documentation: https://docs.ansible.com/
* Ansible systemd_service Module: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_service_module.html
* Minecraft Server Download: https://www.minecraft.net/en-us/download/server
* Minecraft EULA: https://www.minecraft.net/en-us/eula
* GitHub Markdown Syntax: https://docs.github.com/en/get-started/writing-on-github/basic-writing-and-formatting-syntax
