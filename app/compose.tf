provider "aws" {
  access_key = "AKIAIOZQINN7DUFVKRVA"
  secret_key = "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"
  region  = "eu-central-1"
  
}

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "ted-project-vpc"
  }
}
resource "aws_subnet" "test" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}
resource "aws_instance" "compose" {
  ami = "ami-0c115dbd34c69a004"
 instance_type = "t2.micro"
 subnet_id  = aws_subnet.test.id
 associate_public_ip_address = true
#  security_groups = ["${aws_security_group.allow_tls.id}"]
 key_name = "key"
 tags = {
    Name = "ted-search"
    }
 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("./key.pem")
    host     = "${aws_instance.compose.public_ip}"
  }
  
  
 
  provisioner "file" {
    source      = "/home/gangoll/Downloads/ted-search/docker-compose.yml"
    destination = "~/"
  }
provisioner "file" {
    source      = "src"
    destination = "~/"
  }
  provisioner "file" {
    source      = "application.properties"
    destination = "~/"
  }
   provisioner "file" {
    source      = "application.properties"
    destination = "~/"
  }
   provisioner "file" {
    source      = "n.dockerfile"
    destination = "~/"
  }

  
 provisioner "remote-exec" {
    inline = [
    
     "compose.sh",
    ]
    
  }
   
}