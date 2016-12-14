#!/bin/bash
NAME='conkanprog'
# nginxリバースプロキシをホスト上で動かす場合、localhostにのみ9001を公開
PSET='-p 127.0.0.1:9002:9002'
# 同じホスト上でmysqlコンテナを動かす場合、連携
# LNKOPT="--link mysql"
ENVOPT="-e HOSTNAME=${NAME}"
RUNOPT='-d --restart=always'
LOGMNT='-v /var/log/conkanprog:/var/log/conkanprog'

# git cloneしたディレクトリを指定(本番系でDockerのみ使う場合は不要)
GITTOP="$(pwd)"
# 開発時はgit checkout先のappをmountする
DEVMODE=1
DEVMNT="-v ${GITTOP}/app:/root/app"

if [ $1 ]; then
    # 本番系は、run.sh product で起動
    if [ $1 = "product" ] ; then
        DEVMODE=''
        IMGTAG=':1.0.0'
        # backupとconkan.ymlを永続化する
        if ! [ -d $(pwd)/conkan ]; then
            mkdir $(pwd)/conkan 
        fi
        if ! [ -d $(pwd)/backup ]; then
            mkdir $(pwd)/backup 
        fi
        if ! [ -e $(pwd)/conkan/conkan.yml ]; then
            # 開発系で起動したものを本番系に移行する時、
            # 既存の設定ファイルを流用する
            if [ -e ${GITTOP}/app/conkan/conkan.yml ]; then
                cp ${GITTOP}/app/conkan/conkan.yml $(pwd)/conkan/conkan.yml
            else
                docker run -i -t conkan/conkan_program${IMGTAG} cat /root/app/conkan/conkan.yml_default > $(pwd)/conkan/conkan.yml
            fi
        fi
        DEVMNT="-v $(pwd)/backup:/root/app/backup -v $(pwd)/conkan/conkan.yml:/root/app/conkan/conkan.yml"
    fi
    # デバッグ時はconkan_server.plを起動
    if [ $1 = "debug" ] ; then
        RUNCMD='/root/app/conkan/script/conkan_server.pl -r -d -p 9002'
    fi
fi
# 開発時 存在しない場合、conkan.ymlを初期化(でないと起動失敗する)
if [ ${DEVMODE} ]; then
    if ! [ -e ${GITTOP}/app/conkan/conkan.yml ]; then
        cp ${GITTOP}/app/conkan/conkan.yml_default ${GITTOP}/app/conkan/conkan.yml
    fi
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
echo "docker run ${ALLOPT} conkan/conkan_program${IMGTAG} ${RUNCMD}"
docker run ${ALLOPT} conkan/conkan_program${IMGTAG} ${RUNCMD}
