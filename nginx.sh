#!/bin/bash
sudo sed -i "s/ted/$(head -1 to-replace)/g" nginx.conf
sudo cp -r ~/nginx.conf /opt/bitnami/nginx/conf/nginx.conf
sudo cp -r ~/static /opt/bitnami/nginx/html
sudo /opt/bitnami/ctlscript.sh restart nginx

