# Minecraft Server on AWS
CS 312 Final Course project where we will design and implement an automated Minecraft server that can deploy and reboot entirely without manual intervention through the AWS Management Console. This will be achieved by using Terraform and Docker.

## Prerequisites
### Installing CLIs:

Install the Terraform CLI: [Install Terraform | Terraform | HashiCorp DeveloperLinks to an external site.](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

Install the AWS CLI: [Installing or updating the latest version of the AWS CLI - AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Configure Credentials
Start your AWS Academy Learner Lab.

Click on "AWS Details" in the top right corner of your Learner Lab page.

Create the file `~/.aws/credentials` and copy the credentials from "AWS CLI" in your "AWS Details" tab. Save the file.

## Set up automation scripts
### Creating a keypair
If you already have a key you may skip this step.

If you don't have a keypair, run the following command to generate one:

`ssh-keygen -t rsa -b 4096 -a 100 -f ~/mykeyfile`
This will create a file "mykeyfile" and "mykeyfile.pub" in your HOME directory


### Creating files
Create the file `scripts/install.sh` and copy paste the following below:
``` sh
sudo apt-get update -y
sudo apt-get install -y docker.io

sudo systemctl start docker
sudo systemctl enable docker
sudo docker run -d --restart=always -p 25565:25565 -e EULA=TRUE itzg/minecraft-server
```

Create a file called `terraform/main.tf` and copy paste the following below:

>[!NOTE]  
> Replace "~/mykeyfile" with your keypair name and path. Replace "your_absolute_path" with the absolute path to your script file.

``` tf
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
  region  = "us-west-2" # Or your Region of choice
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
      private_key = "${file("{~/mykeyfile}")}"
    }
    inline = [
      "${file("{your_absolute_path}/install.sh")}"
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
```

## Running the Server
Navigate to the terraform directory:  
`cd terraform/`

Initialize Terraform:  
`terraform init`

Apply the configuration (type "yes" when prompted):  
`terraform apply`