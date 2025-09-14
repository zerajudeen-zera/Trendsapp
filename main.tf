terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.10.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

#Create a VPC
resource "aws_vpc" "trendsapp_vpc" {
    cidr_block = "172.0.0.0/16"
    tags = {
        Name = "trendsapp_vpc"
    }


}
#subnet creation
resource "aws_subnet" "trendsapp_public_subnet"{
    vpc_id = aws_vpc.trendsapp_vpc.id
    cidr_block = "172.0.1.0/24"
    availability_zone = "ap-south-1a"

    tags = {
        Name = "trendsapp_public_subnet"
    }
}
#Internet Gateway creation
resource "aws_internet_gateway" "trendsapp_igw" {
    vpc_id = aws_vpc.trendsapp_vpc.id

    tags = {
        Name = "trendsapp_igw"
    }
}

#route table creation
resource "aws_route_table" "trendsapp_public_rt" {
    vpc_id = aws_vpc.trendsapp_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.trendsapp_igw.id
    }
    tags = {
        Name = "trendsapp_public_rt"
    }

}
#route table association
resource "aws_route_table_association" "trendsapp_public_rta" {
    subnet_id = aws_subnet.trendsapp_public_subnet.id
    route_table_id = aws_route_table.trendsapp_public_rt.id
}
#security group creation
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.trendsapp_vpc.id

  tags = {
    Name = "my-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_ssh" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_https" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_http" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_all_custom" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}
resource "aws_vpc_security_group_ingress_rule" "allow_all_jenkins" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#IAM role creation
resource "aws_iam_role" "jenkins_role" {
    name = "trendsapp_ec2_role"
    assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    EOF
}

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
    name = "trendsapp_ec2_instance_profile"
    role = aws_iam_role.jenkins_role.name

}

resource "aws_iam_role_policy_attachment" "jenkins_cluster_attach" {
    role = aws_iam_role.jenkins_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

resource "aws_iam_role_policy_attachment" "jenkins_nodepolicy_attach" {
    role = aws_iam_role.jenkins_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

}


resource "aws_eip" "myeip" {
    domain = "vpc"
    instance = aws_instance.trendsapp_ec2.id
    tags = {
        Name = "trendsapp_eip"
    }
}
resource "aws_instance" "trendsapp_ec2" {
    ami = "ami-02d26659fd82cf299" #Amazon ubuntu
    instance_type = "t3.micro"
    subnet_id = aws_subnet.trendsapp_public_subnet.id
    vpc_security_group_ids = [aws_security_group.allow_all.id]
    volume_tags = {
        Name = "trendsapp_ec2_volume"
        size = "30"
        type = "gp3"
    }
    key_name = "trendsapp_keypair"
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install openjdk-21-jre -y
                sudo apt update -y
                sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
                https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
                echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
                sudo apt-get update -y
                sudo apt-get install jenkins -y
                sudo systemctl start jenkins
                sudo systemctl enable jenkins
                EOF

    tags = {
        Name = "trendsapp_ec2"
    }
    iam_instance_profile = aws_iam_instance_profile.jenkins_instance_profile.name
}


        