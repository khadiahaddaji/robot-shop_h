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

resource "aws_instance" "my_vm" {
  ami           = "ami-03b82db05dca8118d" 
  instance_type = "t2.micro"
  key_name     = "my-generated-key"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_access.id] 
  associate_public_ip_address = true  
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y java-1.8.0-openjdk
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/jenkins.io.key
    sudo yum install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    sudo firewall-cmd --permanent --add-port=8080/tcp
    sudo firewall-cmd --reload
  EOF
  tags = {
    Name = "OPS-vpc"          
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my_vm.id
  allocation_id = aws_eip.my_eip.id
}

resource "aws_security_group" "ssh_access" {
  name        = "allow-ssh"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id  

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow-SSH"
  }
}

resource "aws_ecr_repository" "ECR_0PS" {
  name                 = "ecr-0ps"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
