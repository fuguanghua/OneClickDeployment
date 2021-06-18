#!/bin/sh
##############################################################
#  Create for : artfpack.sh                                  #
#  Create on  : 2016-08-01                                   #
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

#判断是否已存在artf目录
if [ ! -d ${ARTFDIR} ];then
    echo "${ARTFDIR}目录不存在"
    exit 0
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

#打印执行信息
PrtMsg "[${ARTFNM}]打包操作...\n" "$BOLD" "$NORM"


ProcPkSqlData(){
    PrtMsg "[${ARTFNM}]交易配置导出开始" "$BOLD" "$NORM"
    
    #将配置文件导向ARTFSQLDATA换版目录
    export FDIR=${ARTFSQLDATA}
    
    #交易配置导出
    sh ${ARTFSQLDATA}/${ARTFNO}o.sh
    
    PrtMsg "[${ARTFNM}]交易配置导出完成" "$BOLD" "$NORM"
}

ProcPkSameCopy(){
    PrtMsg "[${ARTFNM}]可执行文件打包开始" "$BOLD" "$NORM"
    
    #定义临时操作文件
    PkSameCopy=${HOME}/tmp/PkSameCopy.tm
    
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并组操作语句
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")}  {printf("cp -p %s ",$0)} {printf("'${ARTFSAMECOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";\n")}' > ${PkSameCopy}
    
    #执行打包操作
    sh ${PkSameCopy}
    #cat ${PkSameCopy}
    rm -f ${PkSameCopy}
    
    PrtMsg "[${ARTFNM}]可执行文件打包完成" "$BOLD" "$NORM"
}

ProcPkTar(){
    PrtMsg "[${ARTFNM}]tar包开始" "$BOLD" "$NORM"
    
    #在${PWDDIR}目录内打包
    tar cvf ${ARTFNM}.tar ${ARTFNM}
    
    PrtMsg "[${ARTFNM}]tar包完成" "$BOLD" "$NORM"
}

ProcPkSqlData
ProcPkSameCopy
ProcPkTar
