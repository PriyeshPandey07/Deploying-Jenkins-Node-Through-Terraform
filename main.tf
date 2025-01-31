provider "aws" {
  region     = "ap-south-1"
  access_key = "put your access key here"
  secret_key = "put your secret key here"
}

resource "tls_private_key" "mykey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "mykey"
  public_key = tls_private_key.mykey.public_key_openssh
}

# Create a VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "jenkins_vpc"
  }
}

# Create a Subnet
resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "kube_subnet"
  }
}

# Create a Security Group
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.jenkins_vpc.id

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

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

#9000 port for sonarqube if needed
  ingress {
    from_port   = 9000
    to_port     = 9000
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
    Name = "jenkins_sg"
  }
}

resource "aws_instance" "Jenkins_Server" {
  ami                    = "replace with your AMI ID"
  instance_type          = "t2.medium" #t2.mdeium is the minimum requirement for jenkins
  subnet_id              = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

#jenkins server should have 30GB of storage
root_block_device {
    volume_size = 30  # Specify the desired root volume size here
    volume_type = "gp3"  # General Purpose SSD
    delete_on_termination = true  # Delete the volume when the instance is terminated
  } 
  tags = {
    Name = "Jenkins-Server"
  }
}

resource "aws_instance" "Jenkins_Agent" {
  ami                    = "replace with your AMI ID"
  instance_type          = "t2.medium" #t2.mdeium is the minimum requirement for jenkins
  subnet_id              = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

#jenkins agent should have 30GB of storage
root_block_device {
  volume_size = 30  # Specify the desired root volume size here
  volume_type = "gp3"  # General Purpose SSD
  delete_on_termination = true  # Delete the volume when the instance is terminated
  }
  tags = {
    Name = "Jenkins-Agent"
  }
}
