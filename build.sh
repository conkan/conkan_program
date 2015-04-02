#!/bin/bash
# Azureで動かす場合、build.sh azure
if [ "$1" = "azure" ] ; then
    AZDO='--tls -H tcp://conkan.cloudapp.net:4243'
else
    unset AZDO
fi
docker $AZDO build --force-rm=true -t srem/conkan .
unset AZDO
