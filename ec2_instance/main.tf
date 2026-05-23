terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Настройка провайдера AWS и путей к твоим ключам
provider "aws" {
  region                   = "us-east-1"
}

# Динамический поиск самого свежего образа Amazon Linux 2 (Data Source)
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

# Создаем виртуальный сервер (EC2 Instance)
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  
  # Здесь указывается имя твоего SSH-ключа. В AWS Academy по умолчанию ключ называется "vockey".
  # Если в твоем аккаунте ключ называется "lab1" (как на скринах в Lab 1.1), оставь "lab1".
  key_name               = "vockey" 
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "New webserver"
  }

  # Скрипт автозапуска (выполняется один раз при первом старте сервера)
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<html><h1>Your webserv works! Awesome!</h1><h2>Mirza IMIm25-1</h2></html>" > /var/www/html/index.html
              EOF
}

# Настройка фаервола (Security Group)
resource "aws_security_group" "web_sg" {
  name        = "Ec2 instance sg"
  description = "Security Group for EC2 Web Server"

  # Разрешаем входящий веб-трафик (порт 80) для всех
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Разрешаем SSH (порт 22) для всех (для простоты сдачи лабы)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Разрешаем серверу скачивать пакеты из интернета (любой исходящий трафик)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Выводим на экран публичный DNS-адрес созданного сервера
output "website_endpoint" {
  value = aws_instance.web.public_dns
}
