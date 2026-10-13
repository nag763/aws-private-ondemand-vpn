terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

variable "aws_region" {
  description = "AWS region to deploy the VPN in"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID to use for the VPN server"
  type        = string
}

variable "wg_port" {
  description = "WireGuard UDP listen port"
  type        = number
  default     = 52180
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB (8 GB is minimal for Amazon Linux 2023)"
  type        = number
  default     = 8
}

variable "root_volume_type" {
  description = "EBS storage tier for the root volume (default gp3 is low-cost SSD; magnetic 'standard' is also supported)"
  type        = string
  default     = "gp3"
}

variable "admin_cidr" {
  description = "CIDR block permitted for SSH management. Defaults to deployer's current public IP."
  type        = string
  default     = null
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/terraform.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for provisioning"
  type        = string
  default     = "~/.ssh/terraform"
}

provider "aws" {
  region = var.aws_region
}

# Automatically fetch deployer IP to restrict SSH access
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  admin_cidr = var.admin_cidr != null ? var.admin_cidr : "${chomp(data.http.my_ip.response_body)}/32"
}

# Step 1: Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpn-vpc"
  }
}

# Step 2: Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "vpn-igw"
  }
}

# Step 3: Create a Route Table and Route for Internet Access
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "vpn-rt"
  }
}

resource "aws_route" "route_to_internet" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Step 4: Create a Subnet and Associate it with the Route Table
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpn-subnet"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Step 5: Create a Security Group and Open Ports
resource "aws_security_group" "vpn_sg" {
  name        = "vpn-security-group"
  description = "Security group for WireGuard VPN server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "vpn-sg"
  }
}

# Allow SSH only from admin CIDR (TCP only, not UDP or 0.0.0.0/0)
resource "aws_vpc_security_group_ingress_rule" "inbound_ssh" {
  security_group_id = aws_security_group.vpn_sg.id
  cidr_ipv4         = local.admin_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH management restricted to admin IP"
}

# Allow WireGuard only on UDP (not TCP)
resource "aws_vpc_security_group_ingress_rule" "inbound_wireguard" {
  security_group_id = aws_security_group.vpn_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "udp"
  from_port         = var.wg_port
  to_port           = var.wg_port
  description       = "WireGuard UDP traffic"
}

# Allow outbound traffic
resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.vpn_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

# Step 6: Create a Key Pair for SSH Access
resource "aws_key_pair" "ec2" {
  key_name   = "ec2-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# Step 7: Launch an EC2 Instance
resource "aws_instance" "ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ec2.key_name
  vpc_security_group_ids      = [aws_security_group.vpn_sg.id]
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    scripts = [
      "scripts/instance/create-wgconf.sh",
      "scripts/instance/generate-client.sh",
      "scripts/instance/exit-actions.sh"
    ]
  }

  tags = {
    Name = "vpn-instance"
  }
}

output "public_ip" {
  description = "Public IP of the WireGuard VPN instance"
  value       = aws_instance.ec2.public_ip
}
