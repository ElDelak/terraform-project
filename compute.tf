resource "aws_instance" "myec2" {
  ami                    = "7cfecami-0c7217cdde31"
  instance_type          = "t2.micro"
  key_name               = "mykey"
  vpc_security_group_ids = [aws_security_group.mysg.id]

  # Attach IAM Role for AWS permissions (including SQS)
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./tools/private_key.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "./tools/generate_data.py"                # Specify the path to your local file
    destination = "/home/ubuntu/generate_data.py" # Specify the destination path on the remote instance
  }

  provisioner "file" {
    source      = "./tools/importMqttEc2.py"                # Specify the path to your local file
    destination = "/home/ubuntu/importMqttEc2.py" # Specify the destination path on the remote instance
  }
    provisioner "file" {
    source      = "./tools/queue_wrapper.py"                # Specify the path to your local file
    destination = "/home/ubuntu/queue_wrapper.py" # Specify the destination path on the remote instance
  }

  user_data = <<EOT
  #!/bin/bash

  (crontab -l; echo "@reboot python3 /home/ubuntu/importMqttEc2.py") | crontab -
  (crontab -l; echo "@reboot python3 /home/ubuntu/generate_data.py") | crontab -
              
  EOT

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y python3",
      "sudo apt install -y python3-pip",
      "pip install paho-mqtt",
      "sudo apt-get update -y",
      "sudo apt-get install -y python3-boto3",
      "sudo apt-get install -y awscli",  # Install AWS CLI
      "aws configure --profile aws set region us-east-1",  # Set your desired region
      "aws configure --profile aws set output json",
      "sudo chmod +x /home/ubuntu/importMqttEc2.py",
      "sudo chmod +x /home/ubuntu/generate_data.py",
      "nohup python3 /home/ubuntu/importMqttEc2.py &",
      "nohup python3 /home/ubuntu/generate_data.py &"
    ]
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_policy" "ec2_policy" {
  name = "ec2_policy"
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "ec2:startInstances",
          "ec2:stopInstances"

        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

# Create IAM role to give the EC2 instance permission to interact with AWS services
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

# attach the policy to the role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
} 

# Create an IAM instance profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_security_group" "mysg" {
  name        = "example-security-group"
  description = "Allow SSH, mqtt inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from any IP address (for demonstration purposes)
  }

  ingress {
    from_port   = 1883
    to_port     = 1883
    protocol    = "tcp"
    cidr_blocks = ["91.121.93.94/32"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
