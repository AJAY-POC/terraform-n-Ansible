provider "aws" {
  region = "ap-northeast-1"
}

# Create VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "172.0.0.0/16"
 tags = {
    Name = "k8s-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "172.0.1.0/24" 
  availability_zone = "ap-northeast-1a" 

  tags = {
    Name = "k8s-subnet"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.k8s_vpc.id
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.example.id
}

# Create Security Group for Kubernetes nodes
resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-security-group"
  }
}


# Create EC2 Instances for Kubernetes master and worker nodes
resource "aws_instance" "k8s_master" {
  ami           = "ami-0d52744d6551d851e"  # Replace with your desired AMI ID
  instance_type = "t2.medium"  # Replace with your desired instance type
  key_name      = "keypair1"  # Replace with your desired SSH key pair name
  subnet_id     = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s_node1" {
  ami           = "ami-0d52744d6551d851e"  # Replace with your desired AMI ID
  instance_type = "t2.medium"  # Replace with your desired instance type
  key_name      = "keypair1"  # Replace with your desired SSH key pair name
  subnet_id     = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "k8s-node1"
  }
}

output "k8s_master" {
  value = aws_instance.k8s_master.public_ip
}

output "k8s_node1" {
  value = aws_instance.k8s_node1.public_ip
}


/* resource "null_resource" "inventory_creation" {
    depends_on = [
     aws_instance.k8s_master,
      aws_instance.k8s_node1,
    ]

provisioner "local-exec" {
  command = <<EOT
sudo -S sh -c 'cat <<EOF > /etc/ansible/hosts
k8s-master ansible_host=${aws_instance.kubernetes_master.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/root/poc.keypair.pem ansible_ssh_extra_args="-o StrictHostKeyChecking=accept-new"
k8s-node1 ansible_host=${aws_instance.kubernetes_node1.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/root/poc.keypair.pem ansible_ssh_extra_args="-o StrictHostKeyChecking=accept-new"
EOF'
    EOT
  }
}
*/
