#!/bin/bash
# Azureで動かす場合、run.sh azure
if [ "$1" = "azure" ] ; then
    AZDO='--tls -H tcp://conkan.cloudapp.net:4243'
    HP='80'
    HS='443'
else
    unset AZDO
    HP='30080'
    HS='30443'
fi
docker $AZDO stop conkan
docker $AZDO rm conkan
docker $AZDO run -d --name conkan -p $HP:80 -p $HS:443 -v `pwd`/app:/root/app srem/conkan
unset AZDO
unset HP
unset HS
