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
  region  = "us-west-2"
}

resource "aws_key_pair" "minecraft_key" {
  key_name   = "minecraft-key"
  public_key = file("~/mykeyfile.pub")
}

resource "aws_instance" "minecraft_server" {
  ami           = "ami-0a605bc2ef5707a18" # Ubuntu
  instance_type = "t3.medium"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  key_name = aws_key_pair.minecraft_key.key_name
  tags = { Name = "MinecraftServer" }

  provisioner "remote-exec" {
    connection {
      host = "${self.public_dns}"
      user = "ubuntu"
      type = "ssh"
      private_key = "${file("~/mykeyfile")}"
    }
    inline = [
      "${file("/Users/austinnakamatsu/Desktop/CS312/final/minecraft/scripts/dinstall.sh")}"
    ]
  }
}

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-sg"
  description = "Allow Minecraft traffic"
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH port"
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
}

output "minecraft_server_ip" {
  description = "Public IP of the Minecraft server"
  value       = aws_instance.minecraft_server.public_ip
}