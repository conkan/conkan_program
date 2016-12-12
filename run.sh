#!/bin/bash
NAME='conkanprog'
PSET='-p 127.0.0.1:9002:9002'
RUNOPT='-d --restart=always'
LOGMNT='-v /var/log/conkanprog:/var/log/conkanprog'
# 本番系は、run.sh product で起動
if [ "$1" = "product" ] ; then
    DEVMNT=''
else
    # 開発時はgit checkout先をmountする
    DEVMNT='-v '$(pwd)'/app:/root/app'
    # 存在しない場合、conkan.ymlを初期化(でないと起動失敗する)
    if ! [ -e `pwd`/app/conkan/conkan.yml ]; then
        cp `pwd`/app/conkan/conkan.yml_default `pwd`/app/conkan/conkan.yml
    fi
fi

# デバッグ時はconkan_server.plを起動
if [ "$1" = "debug" ] ; then
    RUNCMD='/root/app/conkan/script/conkan_server.pl -r -d -p 9002'
fi

STAT=`docker inspect $NAME | grep Status | awk -F'"' '{print $4}'`
if [ !${STAT} ]; then
    STAT=`docker inspect $NAME | grep Running | awk '{print $2}'`
    if [ ${STAT} == 'true,' ]; then
        STAT='running'
    fi
fi
if [ ${STAT} ]; then
    if [ ${STAT} == 'running' ]; then
        docker stop ${NAME}
    fi
    docker rm ${NAME}
fi
docker run ${RUNOPT} --name ${NAME} ${PSET} ${LOGMNT} ${DEVMNT} conkan/conkan_program ${RUNCMD}
