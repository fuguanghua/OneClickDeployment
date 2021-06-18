#!/bin/sh
##############################################################
#  Create for : artfbeifen.sh                                #
#  Create on  : 2016-08-01                                   #
#  System of  : HP-UNIX                                      #
##############################################################
PID=$$

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
ARTFTMP="$HOME/tmp/artf"
mkdir -p ${ARTFTMP}

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
if [ -d ${ARTFDIR} ];then
    mv ${ARTFDIR} ${ARTFDIR}.bak.`date +'%m%d%H%M%S'`
fi
if [ -s ${ARTFNM}.tar ];then
    PrtMsg "[${ARTFNM}]解压换版包[${ARTFNM}.tar]" "$NORM" "$NORM"
    tar xvf ${ARTFNM}.tar 2>&1 1>/dev/null
else
    PrtMsg "${ARTFDIR}.tar不存在" "$NORM" "$NORM"
    exit 0
fi

#打印执行信息
PrtMsg "\n[${ARTFNM}]备份开始...\n" "$BOLD" "$NORM"

OperateDB()
{
    DBNM=$1
    File=$2
    Ret=$3
    dbaccess ${DBNM} < ${File} 2>&1
    eval ${Ret}=$?
}

ProcBfSqlData(){
    PrtMsg "[${ARTFNM}]交易配置备份开始" "$BOLD" "$NORM"
    
    DbmBakDir=$HOME/bak/${CFGDBNAME}/`date +%Y%m%d`
    if [ -d ${DbmBakDir} ];then
        PrtMsg "[${ARTFNM}]当日数据库备份已存在:${DbmBakDir}" "$BOLD" "$NORM"
    else
        PrtMsg "[${ARTFNM}]数据库备份..." "$BOLD" "$NORM"
        DBM -b
    fi
    
    #将配置文件导向ARTFDATABAK备份目录
    export FDIR=${ARTFDATABAK}
    
    #交易配置备份
    sh ${ARTFSQLDATA}/${ARTFNO}o.sh
    
    PrtMsg "[${ARTFNM}]交易配置备份完成" "$BOLD" "$NORM"
}

ProcBfDiffCopy(){
    PrtMsg "[${ARTFNM}]配置文件备份开始" "$BOLD" "$NORM"
    
    #定义临时操作文件
    BfDiffCopy=${ARTFTMP}/BfDiffCopy.tm.${PID}
    
    #读取配置文件${ARTFDIFFCOPY}/diffcopy.list内容并组操作语句
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFDATABAK}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFDATABAK}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")}  {printf("if [ -s %s ];then cp -p %s ",$0,$0)} {printf("'${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";fi;\n")}' > ${BfDiffCopy}
    
    #执行备份操作
    sh ${BfDiffCopy}
    cat ${BfDiffCopy}
    rm -f ${BfDiffCopy}
    
    PrtMsg "[${ARTFNM}]配置文件备份完成" "$BOLD" "$NORM"
}

ProcBfSameCopy(){
    PrtMsg "[${ARTFNM}]可执行文件备份开始" "$BOLD" "$NORM"
    
    #定义临时操作文件
    BfSameCopy=${ARTFTMP}/BfSameCopy.tm.${PID}
    
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并组操作语句
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFDATABAK}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFDATABAK}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")}  {printf("if [ -s %s ];then cp -p %s ",$0,$0)} {printf("'${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";fi;\n")}' > ${BfSameCopy}
    
    #执行备份操作
    sh ${BfSameCopy}
    cat ${BfSameCopy}
    rm -f ${BfSameCopy}
    
    PrtMsg "[${ARTFNM}]可执行文件备份完成" "$BOLD" "$NORM"
}

ProcBfDbOperate(){
    PrtMsg "[${ARTFNM}]数据库操作备份开始: " "$BOLD" "$NORM"
    
    DBNAME=$1
    filesql=$2
    
    cd ${ARTFDATABAK}
    if [ `cat $filesql | grep -v "^--" | grep -v "^$" | wc -l` -ne 0 ];then
        cat $filesql | grep -v "^--" | grep -v "^$"
        OperateDB "$DBNAME" "$filesql" "Ret"
        if [ ${Ret} -ne "0" ]
        then
            echo "[$filesql]数据库操作失败" 
        fi
    fi
    cd -
    
    PrtMsg "[${ARTFNM}]数据库操作备份结束: " "$BOLD" "$NORM"
}

ProcBfList(){
    PrtMsg "[${ARTFNM}]备份目录及文件如下: " "$BOLD" "$NORM"
    #列出所有的备份文件
    ls -R ${ARTFDATABAK}
}

ProcBfSqlData
ProcBfDiffCopy
ProcBfSameCopy
ProcBfDbOperate "$RUNDBNAME" "${ARTFDBOPERATE}/rundbbeifen.sql"
ProcBfDbOperate "$CFGDBNAME" "${ARTFDBOPERATE}/cfgdbbeifen.sql"
ProcBfList

PrtMsg "\n[${ARTFNM}]备份结束...\n" "$BOLD" "$NORM"
