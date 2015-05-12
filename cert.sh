#!/bin/bash
if [ "$1" == "" ] ; then
    echo "Usage: $0 [CN]"
    exit
fi
certdir=`pwd`/app/.ssh
if ! [ -e ${certdir} ]; then
    mkdir ${certdir}
    chmod 0755 ${certdir}
fi
cd ${certdir}
openssl req -batch -newkey rsa:2048 -nodes -subj /C=JP/L=hiroshima/O=studio-rem/OU=rem/CN=$1 -out cert.csr -keyout /cert.key
openssl x509 -req -days 365 -in cert.csr -signkey cert.key -out cert.crt
chmod 0644 cert.csr cert.crt
chmod 0600 cert.key
chown root:root ${certdir} cert.csr cert.crt cert.key
