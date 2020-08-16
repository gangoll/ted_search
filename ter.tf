provider "aws" {
  access_key = ""
  secret_key = ""
  region  = "eu-central-1"
  
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "compose-vpc"
  }
}
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
resource "aws_security_group" "compose" {
  name        = "compose"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ghgvh from VPC"
    from_port   = 9191
    to_port     = 9191
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
   description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   egress {
   description = "http from VPC"
    from_port   = 9191
    to_port     = 9191
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   egress {
   description = "http from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "nginx from VPC"
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
   description = "http from VPC"
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_tls"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "main"
  }
}
resource "aws_route_table_association" "main" {
  subnet_id  = aws_subnet.main.id
  route_table_id = aws_route_table.r.id

}

resource "aws_instance" "nginx-instance" {
 ami = "ami-005b8739bcc8cf104"
 instance_type = "t2.micro"
 subnet_id  = aws_subnet.main.id
 associate_public_ip_address = true
 security_groups = ["${aws_security_group.compose.id}"]
 key_name = "key"
 tags = {
    Name = "nginx"
    }
  

connection {
    type     = "ssh"
    user     = "bitnami"
    private_key = file("./key.pem")
    host     = "${aws_instance.nginx-instance.public_ip}"
  }

 provisioner "local-exec" {
    command = <<EOH
    "echo $FOO > to-replace"
               "echo $temp > memcached_new_ip",
               EOH
    environment = {
      FOO = "${aws_instance.ted-search-instance.private_ip}",
      temp = "${aws_instance.memcached.private_ip}"
      
    }
  }
provisioner "file" {
    source      = "./nginx.conf"
    destination = "~/nginx.conf"
  }
  
provisioner "file" {
    source      = "to-replace"
    destination = "~/to-replace"
  }
  provisioner "file" {
    source      = "static"
    destination = "~/"
    }

  provisioner "file" {
    source      = "./nginx.sh"
    destination = "~/nginx.sh"
  }
   provisioner "remote-exec" {
    inline = [
  "chmod +x nginx.sh",
  "./nginx.sh",
    ]
  } 
  
  depends_on = [
    aws_instance.ted-search-instance,
    aws_instance.memcached,
  ]
}
resource "aws_instance" "memcached" {
 ami = "ami-005b8739bcc8cf104"
 instance_type = "t2.micro"
 subnet_id  = aws_subnet.main.id
 associate_public_ip_address = true
 security_groups = ["${aws_security_group.allow_tls.id}"]
 key_name = "key"
 tags = {
    Name = "memcached"
    }
  

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("./key.pem")
    host     = "${aws_instance.memcached.public_ip}"
  }

  # memcached_new_ip
   provisioner "remote-exec" {
    inline = [
    "sudo yum update -y",
    "yum -y install memcached",
     "nohup systemctl start memcached &",
     "sleep 5",
    ]
    
  }
 
}

resource "aws_instance" "ted-search-instance" {
  ami = "ami-0c115dbd34c69a004"
 instance_type = "t2.micro"
 subnet_id  = aws_subnet.main.id
 associate_public_ip_address = true
 security_groups = ["${aws_security_group.allow_tls.id}"]
 key_name = "key"
 tags = {
    Name = "ted-search"
    }
 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("./key.pem")
    host     = "${aws_instance.ted-search-instance.public_ip}"
  }
  provisioner "local-exec" {
    command = "echo $temp > memcached_new_ip"
    environment = {
      
      temp = "${aws_instance.ted-search-instance.private_ip}"
      
    }
  }
  provisioner "file" {
    source      = "./app/target"
    destination = "~/"
  }
   provisioner "file" {
    source      = "./app/application.properties"
    destination = "~/application.properties"
  }
  provisioner "file" {
    source      = "./memcached_new_ip"
    destination = "~/memcached_new_ip"
  }
 provisioner "remote-exec" {
    inline = [
    
     "ted.sh",

    ]
    
  }
   depends_on = [
    aws_vpc.main,
  ]
}
output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.nginx-instance.public_ip
}
