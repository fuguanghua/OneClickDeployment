#!/bin/sh
##############################################################
#  Create for : artfupdate.sh                                #
#  Create by  : weiqs                                        #
#  Create on  : 2016-08-01                                   #
#  Create at  : Bank of ShangHai                             #
#  System of  : HP-UNIX                                      #
##############################################################

[ $# -ne 1 ] && {
    echo "请输入artf版本编号,如: artf12345"
    exit 0
}

isatrf=`echo $1 | grep -E 'artf([0-9]{3,8})$' | wc -l`
if [ $isatrf -eq 0 ];then
    echo "你输入artf编号非法"
    exit 0
fi

#artf编号
ARTFNM=$1

#获取artf号
ARTFNO=`echo ${ARTFNM} | sed 's/\/$//' | awk -F '/' '{print $NF}' | sed 's/artf//g'`
#echo ${ARTFNO}

#定义操作目录
PWDDIR=`pwd`
ARTFDIR=${PWDDIR}/${ARTFNM}
ARTFDATABAK=${ARTFDIR}/databak
ARTFDIFFCOPY=${ARTFDIR}/diffcopy
ARTFSAMECOPY=${ARTFDIR}/samecopy
ARTFSQLDATA=${ARTFDIR}/sqldata
ARTFDBOPERATE=${ARTFDIR}/dboperate
ARTFOLD=${PWDDIR}/old

if [ ! -d ${ARTFOLD} ];then
    mkdir -p ${ARTFOLD}
fi

#定义打印格式
NORM="\033[0m"
BOLD="\033[1m"
BLNK="\033[5m"
HIGH="\033[7m"

#打印函数
PrtMsg()
{
    mesg=$1
    head=$2
    tail=$3

    echo "${head}${mesg}${tail}"
}

#判断是否已存在artf目录
if [ ! -d ${ARTFNM} ];then
    if [ -s ${ARTFNM}.tar ];then
        PrtMsg "[${ARTFNM}]解压换版包[${ARTFNM}.tar]" "$NORM" "$NORM"
        tar xvf ${ARTFNM}.tar
        #将原版本备份
        mv ${ARTFNM}.tar ${ARTFOLD}/${ARTFNM}_old_`date +%Y%m%d%H%M%S`.tar
    else
        PrtMsg "${ARTFDIR}.tar不存在" "$NORM" "$NORM"
        exit 0
    fi
else
    if [ -s ${ARTFNM}.tar ];then
        PrtMsg "[${ARTFNM}]目录已存在，是否需要重新解压${ARTFNM}.tar [y/n]?" "$BOLD" "$NORM"
        read anser?
        case $anser in
        Y|y)
            PrtMsg "你输入的是[$anser],重新解压${ARTFNM}.tar..." "$NORM" "$NORM"
            PrtMsg "[${ARTFNM}]解压换版包[${ARTFNM}.tar]" "$NORM" "$NORM"
            tar xvf ${ARTFNM}.tar
            #将原版本备份
            mv ${ARTFNM}.tar ${ARTFOLD}/${ARTFNM}_old_`date +%Y%m%d%H%M%S`.tar
            ;;
        *)
            PrtMsg "你输入的是[$anser],不解压${ARTFNM}.tar..." "$NORM" "$NORM"
            ;;
        esac
    fi
fi

#打印执行信息
PrtMsg "[${ARTFNM}]编译环境更新操作...\n" "$BOLD" "$NORM"


ProcUpSameCopy(){
    PrtMsg "[${ARTFNM}]可执行文件更新开始" "$BOLD" "$NORM"
    
    #定义临时操作文件
    UpSameCopy=${HOME}/tmp/UpSameCopy.tm
    
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并组操作语句
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | grep -E "\/lib\/|\/bin\/" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")} {printf("if [ -s %s ];then cp -p %s ",$0,$0)} {printf("'${ARTFSAMECOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";fi;\n")}' > ${UpSameCopy}
    
    #执行备份操作
    sh ${UpSameCopy}
    cat ${UpSameCopy}
    rm -f ${UpSameCopy}
    
    PrtMsg "[${ARTFNM}]可执行文件更新完成" "$BOLD" "$NORM"
}

ProcPkTar(){
    PrtMsg "[${ARTFNM}]tar包开始" "$BOLD" "$NORM"
    
    #在${PWDDIR}目录内打包
    tar cvf ${ARTFNM}.tar ${ARTFNM}
    
    PrtMsg "[${ARTFNM}]tar包完成" "$BOLD" "$NORM"
}

ProcUpSameCopy
ProcPkTar
