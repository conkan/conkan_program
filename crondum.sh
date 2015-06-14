#!/bin/bash
while [ true ]; do
    sleep 14400
    `pwd`/dbbackup.sh
    `pwd`/logrotate.sh
    sleep 72000
done
