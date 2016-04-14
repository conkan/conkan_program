#!/bin/bash
if [ "$1" ]; then
        MRPW=$1
    else
            echo 'Usage: run.sh <MYSQL_ROOT_PASSWD>'
                exit
            fi
        docker stop mysql
    docker rm mysql
docker run  -d --restart='always' --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=$MRPW -e HOSTNAME=mysql -v `pwd`/mysql:/var/lib/mysql mysql:5.5
