# Generate a new private key (you can also move this to keypair.tf later if modularizing)
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a new key pair in AWS using the public part of the above key
resource "aws_key_pair" "devsecops_key" {
  key_name   = "devsecops-project"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# AWS EC2 instance resource definition
resource "aws_instance" "ec2" {
  # Use the dynamically retrieved AMI ID from the AWS AMI data source
  ami                    = data.aws_ami.ami.image_id
  
  # Instance type for the EC2 instance, parameterized for flexibility
  instance_type          = var.instance_type  # parameterized for flexibility
  
  # The key pair name for SSH access to the instance
   key_name               = aws_key_pair.devsecops_key.key_name
  
  
  # Subnet ID where the EC2 instance will be launched (usually public subnet)
  subnet_id              = aws_subnet.public-subnet.id
  
  # Security group IDs to control inbound and outbound traffic
  vpc_security_group_ids = [aws_security_group.security-group.id]
  
  # IAM instance profile to attach policies to the EC2 instance
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name
  
  # Root block device configuration, setting the volume size to 30 GB
  root_block_device {
    volume_size = 30
  }

  
  
  # User data script executed on instance launch
  user_data = templatefile("./scripts/tools-install.sh", {})

  # Tags for identifying and organizing the EC2 instance
  tags = {
    Name        = var.instance_name
  }
}

# Outputs to access instance details after creation
output "instance_id" {
  value = aws_instance.ec2.id
}

output "instance_public_ip" {
  value = aws_instance.ec2.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
