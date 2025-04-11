terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

locals {
  inbound_opened = {
    "ssh" : {
      "port": "22",
      "cidr": "0.0.0.0/0"
    },
    "wg" : {
      "port": "52180",
      "cidr": "0.0.0.0/0"
    }
  }
}



# Step 1: Create the VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Step 2: Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Step 3: Create a Route Table and Route for Internet Access
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "route_to_internet" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Step 4: Create a Subnet and Associate it with the Route Table
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Step 5: Create a Security Group and Open Ports (SSH and WireGuard)
resource "aws_security_group" "allow_tls" {
  name        = "allow_all"
  description = "Allow All Traffic"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "inbound_tcp" {
  for_each          = local.inbound_opened
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = each.value.cidr
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
}

resource "aws_vpc_security_group_ingress_rule" "inbound_udp" {
  for_each          = local.inbound_opened
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = each.value.cidr
  ip_protocol       = "udp"
  from_port         = each.value.port
  to_port           = each.value.port
}


resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

# Step 6: Create a Key Pair for SSH Access
resource "aws_key_pair" "ec2" {
  key_name   = "ec2-key"
  public_key = file("~/.ssh/terraform.pub")
}

# Step 7: Launch an EC2 Instance
resource "aws_instance" "ec2" {
  ami                         = "ami-0d6259d29f19a709f"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ec2.key_name
  vpc_security_group_ids      = [aws_security_group.allow_tls.id]
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/terraform")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    scripts = ["./generate-client.sh", "./exit-actions.sh"]
  }
}

output "public_ip" {
  value = aws_instance.ec2.public_ip
}
