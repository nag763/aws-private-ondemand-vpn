packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
  }
}

source "amazon-ebs" "wg-ami" {
  ami_name      = "wg-ami-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "eu-west-3"
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.wg-ami"]

  provisioner "shell" {
    scripts = ["scripts/ami/update-sys.sh", "scripts/ami/enable-wg.sh"]
  }
}
