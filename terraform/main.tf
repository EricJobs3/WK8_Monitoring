terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-southeast-2"
}

resource "aws_security_group_rule" "allow_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = var.sec_gid //
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = var.sec_gid
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = var.sec_gid
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_key_pair" "deployer" {
  key_name   = "ansible-deployer-key"
  public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub")
}

data "aws_ami" "image-ubuntu" {
    filter {
      name   = "name"
      values = ["ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
      name   = "root-device-type"
      values = ["ebs"]
    }

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
}

resource "aws_instance" "monitor" {
  count         = var.ec2_count

  ami           = data.aws_ami.image-ubuntu.id
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"

  tags = {
    Name = (count.index==0 ? "monitor-main" : "monitor-exporter-${count.index}")
    Project = "JRMonitor"
  }
}

