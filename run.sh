#!/bin/bash
NAME='conkanprog'
# nginxリバースプロキシをホスト上で動かす場合、localhostにのみ9001を公開
PSET='-p 127.0.0.1:9002:9002'
# 同じホスト上でmysqlコンテナを動かす場合、連携
# LNKOPT="--link mysql"
ENVOPT="-e HOSTNAME=${NAME}"
RUNOPT='-d --restart=always'
LOGMNT='-v /var/log/conkanprog:/var/log/conkanprog'
# 開発時はgit checkout先のappをmountする(DEVTOPに指定)
DEVTOP="$(pwd)/app"
DEVMNT="-v ${DEVTOP}:/root/app"
# 本番系は、run.sh product で起動
if [ $1 ]; then
    if [ $1 = "product" ] ; then
        if ! [ -d $(pwd)/conkan ]; then
            mkdir $(pwd)/conkan 
        fi
        if ! [ -d $(pwd)/backup ]; then
            mkdir $(pwd)/backup 
        fi
        if ! [ -e $(pwd)/conkan/conkan.yml ]; then
            if [ -e ${DEVTOP}/conkan/conkan.yml ]; then
                cp ${DEVTOP}/conkan/conkan.yml $(pwd)/conkan/conkan.yml
            elif [ -e ${DEVTOP}/conkan/conkan.yml_default ]; then
                cp ${DEVTOP}/conkan/conkan.yml_default $(pwd)/conkan/conkan.yml
            else
                echo "Cannot start ConkanProgram."
                echo "Please create $(pwd)/conkan/conkan.yml"
                echo "(SEE https://conkan.github.io/foruser/devops.html)"
                exit
            fi
        fi
        DEVTOP="$(pwd)"
        DEVMNT="-v ${DEVTOP}/backup:/root/app/backup -v ${DEVTOP}/conkan/conkan.yml:/root/app/conkan/conkan.yml"
        IMGTAG=':1.0.0'
    fi
    # デバッグ時はconkan_server.plを起動
    if [ $1 = "debug" ] ; then
        RUNCMD='/root/app/conkan/script/conkan_server.pl -r -d -p 9002'
    fi
fi
# 存在しない場合、conkan.ymlを初期化(でないと起動失敗する)
if ! [ -e ${DEVTOP}/conkan/conkan.yml ]; then
    cp ${DEVTOP}/conkan/conkan.yml_default ${DEVTOP}/conkan/conkan.yml
fi
MNTOPT="${LOGMNT} ${DEVMNT}"

STAT=`docker inspect ${NAME} | grep Status | awk -F'"' '{print $4}'`
if ! [ ${STAT} ]; then
    STAT=`docker inspect $NAME | grep Running | awk '{print $2}'`
    if [ ${STAT} ]; then
        if [ ${STAT} == 'true,' ]; then
            STAT='running'
        fi
    fi
fi
if [ ${STAT} ]; then
    if [ ${STAT} == 'running' ]; then
        echo "docker stop ${NAME}"
        docker stop ${NAME}
    fi
    echo "docker rm ${NAME}"
    docker rm ${NAME}
fi
ALLOPT="${RUNOPT} --name ${NAME} ${PSET} ${MNTOPT} ${LNKOPT} ${ENVOPT}"
echo "docker run ${ALLOPT} conkan/conkan_program ${RUNCMD}"
docker run ${ALLOPT} conkan/conkan_program${IMGTAG} ${RUNCMD}
