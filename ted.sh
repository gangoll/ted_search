#!/bin/bash
sudo sed -i "s/ted/$(head -1 memcached_new_ip)/g" application.properties
sudo yum update -y
sudo yum install java-1.8.0-openjdk -y
nohup java -jar ./target/embedash-1.1-SNAPSHOT.jar --spring.config.location=./application.properties &