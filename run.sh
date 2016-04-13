#!/bin/bash
# 本番系は、run.sh product で起動
if [ "$1" = "product" ] ; then
    HP='80'
    HS='443'
else
    HP='30080'
    HS='30443'
fi
docker stop conkan
docker rm conkan
# 存在しない場合、conkan.ymlを初期化(でないと起動失敗する)
if ! [ -e `pwd`/app/conkan/conkan.yml ]; then
  cp `pwd`/app/conkan/conkan.yml_default `pwd`/app/conkan/conkan.yml
fi
docker run -d --restart='always' --link mysql --name conkan -p $HP:80 -p $HS:443 -v `pwd`/app:/root/app srem/conkan
