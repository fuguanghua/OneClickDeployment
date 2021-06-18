##############################################################
#  Create for : artfbeifen.sh                                #
#  Create on  : 2016-08-01                                   #
#  System of  : RedHat                                       #
##############################################################
PID=$$

ARTFFLG='^artf([0-9]{3,8})([0-9a-z_.]{0,9})$|^BH_([A-Za-z0-9_.]{3,30})$'

[ $# -ne 1 ] && {
    echo "请输入版本编号,如: artf12345 或者 BH_ESB_20.05.01"
    exit 0
}

isatrf=`echo $1 | grep -E "${ARTFFLG}" | wc -l`
if [ $isatrf -eq 0 ];then
    echo "你输入版本编号非法"
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

#切换服务时备份目录环境变量
export DELARTFDATABAK=${ARTFDATABAK}

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

    echo  -e "${head}${mesg}${tail}"
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
    DBUSER=$2
    DBPWD=$3
    DBADDR=$4
    File=$5
    Ret=$6
    cat ${File} | grep -v "^--" | grep -v "^$" | while read sqlline
    do
        #sqlline=`echo ${sqlline} | sed 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'`
        if [ `echo ${sqlline} | grep "^@" | wc -l` -ne 0 ] && [ `echo ${sqlline} | grep "|" | wc -l` -ne 0 ];then
            OUTFILE=`echo ${sqlline} | awk -F '|' '{print $1}' | sed 's/^@//g'`
            TABLENM=`echo ${sqlline} | awk -F '|' '{print $2}'`
            WHERESTR=`echo ${sqlline} | awk -F '|' '{print $3}'  | sed 's/where//gi'`
            if [ "x${WHERESTR}" != "x" ];then
                echo "delete from ${TABLENM} where ${WHERESTR};" > ${OUTFILE}
                #mysqldump -u${DBUSER} -p${DBPWD} -h${DBADDR} ${DBNM} --complete-insert --no-create-db --no-create-info --compact --set-gtid-purged=OFF --skip-comments ${TABLENM} --where " ${WHERESTR} " 2>/dev/null >> ${OUTFILE}
                isqldump --complete-insert --no-create-db --no-create-info --compact --set-gtid-purged=OFF --skip-comments --skip-triggers ${TABLENM} --where " ${WHERESTR} " 2>/dev/null >> ${OUTFILE}
            else
                echo "delete from ${TABLENM};" > ${OUTFILE}
                #mysqldump -u${DBUSER} -p${DBPWD} -h${DBADDR} ${DBNM} --complete-insert --no-create-db --no-create-info --compact --set-gtid-purged=OFF --skip-comments ${TABLENM} 2>/dev/null >> ${OUTFILE}
                isqldump --complete-insert --no-create-db --no-create-info --compact --set-gtid-purged=OFF --skip-comments --skip-triggers ${TABLENM} 2>/dev/null >> ${OUTFILE}
            fi
        elif [ `echo ${sqlline} | grep "^@" | wc -l` -ne 0 ];then
            sqlline=`echo ${sqlline} | sed 's/^@//g'`
            if [ -s ${sqlline}.${HOSTNMID} ];then
                sqlline=${sqlline}.${HOSTNMID}
            fi
            #mysql -u${DBUSER} -p${DBPWD} -h${DBADDR} ${DBNM} --force -N < ${sqlline} 2>&1 | grep -v "[Warning]"
            isql --force -N < ${sqlline} 2>&1 | grep -v "[Warning]"
        else
            isql --force -N -e " ${sqlline} " 2>&1 | grep -v "[Warning]"
        fi
    done
    eval ${Ret}=$?
}

ProcBfSqlData(){
    PrtMsg "[${ARTFNM}]交易配置备份开始" "$BOLD" "$NORM"
    
    DbmBakDir=$HOME/bak/${CFGDBNAME}/`date +%Y%m%d`
    if [ -d ${DbmBakDir} ];then
        PrtMsg "[${ARTFNM}]当日数据库备份已存在:${DbmBakDir}" "$BOLD" "$NORM"
    else
        PrtMsg "[${ARTFNM}]数据库备份..." "$BOLD" "$NORM"
        #DBM -b
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

    filesql=$5
    
    cd ${ARTFDATABAK}
    if [ `cat $filesql | grep -v "^--" | grep -v "^$" | wc -l` -ne 0 ];then
        cat $filesql | grep -v "^--" | grep -v "^$"
        OperateDB "$1" "$2" "$3" "$4" "$5" "Ret"
        Ret=0
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

if [ "$LOGNAME" = "esbimon" ];then
    cd ${ARTFDATABAK}
    mysqldump_imon
    cd - 2>/dev/null

    ProcBfDbOperate "$DBNM" "$DBUSER" "$DBPWD" "$DBADDR" "${ARTFDBOPERATE}/imondbbeifen.sql"
elif [ "$LOGNAME" = "esbmng" ];then
    cd ${ARTFDATABAK}
    mysqldump_mng
    cd - 2>/dev/null

    ProcBfDbOperate "$DBNM" "$DBUSER" "$DBPWD" "$DBADDR" "${ARTFDBOPERATE}/mngdbbeifen.sql"
fi

ProcBfList

PrtMsg "\n[${ARTFNM}]备份结束...\n" "$BOLD" "$NORM"
