############## 
# VARIABLES
##############

locals {
  vpc_id    = "vpc-bf37acd4"
  subnet_id = "subnet-01bea38ce2853db05"
  ssh_user  = "ubuntu"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "key_name" {}
variable "private_key_path" {}
variable "region" {
  default = "us-east-2"
}

############## 
# PROVIDERS
##############

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

############## 
# RESOURCES
##############

resource "aws_security_group" "nginx" {
  name   = "nginx_access"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                         = "ami-00399ec92321828f5"
  subnet_id                   = local.subnet_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.nginx.id]
  key_name                    = var.key_name

  provisioner "remote-exec" {
    inline = [
    "echo 'Wait until SSH is ready'",
    "sudo apt-get update"
    ]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(var.private_key_path)
      host        = aws_instance.nginx.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i ${aws_instance.nginx.public_ip}, --private-key ${var.private_key_path} nginx.yaml -b"
  }
}

############## 
# OUTPUTS
##############

output "nginx_ip" {
  value = aws_instance.nginx.public_ip
}