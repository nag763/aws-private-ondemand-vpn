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
      name                = "al2023-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.wg-ami"]

  provisioner "shell" {
    scripts = ["./update-sys.sh", "./create-wgconf.sh", "./enable-wg.sh"]
  }
}
