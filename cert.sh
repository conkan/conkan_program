#!/bin/bash
openssl req -batch -newkey rsa:2048 -nodes -out doccnf/cert.csr -keyout doccnf/cert.key
openssl x509 -req -in doccnf/cert.csr -signkey doccnf/cert.key -out doccnf/cert.crt
