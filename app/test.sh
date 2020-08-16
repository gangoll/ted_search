#!/bin/bash

check=`curl -i  http://localhost:8080 | grep -c "HTTP/1.1 200 "`
if [ $check == 1 ] 
then
echo "success"
fi
