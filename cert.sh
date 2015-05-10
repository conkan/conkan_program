#!/bin/bash
openssl req -batch -newkey rsa:2048 -nodes -out app/.ssh/cert.csr -keyout app/.ssh/cert.key
openssl x509 -req -in app/.ssh/cert.csr -signkey app/.ssh/cert.key -out app/.ssh/cert.crt
