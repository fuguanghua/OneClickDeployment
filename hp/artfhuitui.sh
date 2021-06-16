#!/bin/sh
##############################################################
#  Create for : artfhuitui.sh                                #
#  Create by  : weiqs                                        #
#  Create on  : 2016-08-01                                   #
#  Create at  : Bank of ShangHai                             #
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
PrtMsg "\n[${ARTFNM}]回退开始...\n" "$BOLD" "$NORM"

OperateDB()
{
    DBNM=$1
    File=$2
    Ret=$3
    dbaccess ${DBNM} < ${File} 2>&1
    eval ${Ret}=$?
}

ProcHtChkTux(){
    #通过diffcopy.list匹配ubbconfig和dmconfig判断是否需要停止tuxedo服务
    tuxdmflg=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "dmconfig" | wc -l`
    tuxubbflg=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "ubbconfig" | wc -l`

    if [ $tuxdmflg -gt 0 ];then
        #判断BBL是否运行中
        tuxpro=`ps -u "$LOGNAME" | grep -w "BBL" | wc -l`
        while [ $tuxpro -gt 0 ];do
            PrtMsg "tuxedo未停止,请全停应用,10秒后重新检测..." "$NORM" "$NORM"
            tuxpro=`ps -u "$LOGNAME" | grep -w "BBL" | wc -l`
            sleep 10
        done
        
        PrtMsg "[${ARTFNM}]dmconfig编译开始" "$BOLD" "$NORM"
        
        tuxdmnm=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "dmconfig" | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}'`
        dmloadcf -y "${HOME}$tuxdmnm"
        ls -lrt "${HOME}/etc/bdmconfig"
        
        PrtMsg "[${ARTFNM}]dmconfig编译完成" "$BOLD" "$NORM"
    fi

    if [ $tuxubbflg -gt 0 ];then
        #判断BBL是否运行中
        tuxpro=`ps -u "$LOGNAME" | grep -w "BBL" | wc -l`
        while [ $tuxpro -gt 0 ];do
            PrtMsg "tuxedo未停止,请全停应用,10秒后重新检测..." "$NORM" "$NORM"
            tuxpro=`ps -u "$LOGNAME" | grep -w "BBL" | wc -l`
            sleep 10
        done
        
        PrtMsg "[${ARTFNM}]ubbconfig编译开始" "$BOLD" "$NORM"
        
        tuxubbnm=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "ubbconfig" | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}'`
        tmloadcf -y "${HOME}$tuxubbnm"
        ls -lrt "${HOME}/etc/tuxconfig"
        
        PrtMsg "[${ARTFNM}]ubbconfig编译完成" "$BOLD" "$NORM"
    fi
}

ProcHtChkPro(){
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并检查进程是否存在
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep -v "artfhuitui.sh" | awk -F '/' '{split($0,arr,"/")} {printf("%s\n",arr[NF])}' \
        | while read line|| [[ -n ${line} ]];
    do
        proflg=`ps -fu "$LOGNAME" | grep -vE "grep|ldbc.cfg" | grep -w "$line" | wc -l`
        while [ $proflg -gt 0 ];do
            PrtMsg "$line进程未停止,正在执行停$line操作..." "$NORM" "$NORM"
        
            #读取proc.list文件启停进程
            procline=`cat ${HOME}/etc/proc.list | grep -v "^#" | grep -v "^$" | grep -w "$line"`
            if [ "x$procline" != "x" ];then
                Name=`echo ${procline}|awk -F'[\]:\[]' '{print $1}'`
                Star=`echo ${procline}|awk -F'[\]:\[]' '{print $2}'`
                Shut=`echo ${procline}|awk -F'[\]:\[]' '{print $3}'`
                Turn=`echo ${procline}|awk -F'[\]:\[]' '{print $4}'`
                PrtMsg "$line进程未停止，正通过${Shut}停进程..." "$NORM" "$NORM"
                ${Shut}
            else
                PrtMsg "非proc.list中配置的停进程操作，请手工停止..." "$BOLD" "$NORM"
            fi
            
            proflg=`ps -fu "$LOGNAME" | grep -v "grep" | grep -w "$line" | wc -l`
            if [ $proflg -eq 0 ];then
                PrtMsg "$line进程停止成功..." "$NORM" "$NORM"
            fi
            sleep 10
        done
    done
}

ProcHtUpPro(){
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并检查是否需要启进程
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep -v "artfhuitui.sh" | awk -F '/' '{split($0,arr,"/")} {printf("%s\n",arr[NF])}' \
        | while read line|| [[ -n ${line} ]];
    do
        #读取proc.list文件启停进程
        procline=`cat ${HOME}/etc/proc.list | grep -v "^#" | grep -v "^$" | grep -w "$line"`
        if [ "x$procline" != "x" ];then
            Name=`echo ${procline}|awk -F'[\]:\[]' '{print $1}'`
            Star=`echo ${procline}|awk -F'[\]:\[]' '{print $2}'`
            Shut=`echo ${procline}|awk -F'[\]:\[]' '{print $3}'`
            Turn=`echo ${procline}|awk -F'[\]:\[]' '{print $4}'`
            
            if [ ${Turn} = "ON" ];then
                PrtMsg "$line进程未启动，正通过${Star}启进程..." "$NORM" "$NORM"
                ${Star}
            fi
            proflg=`ps -fu "$LOGNAME" | grep -v "grep" | grep -w "$line" | wc -l`
            if [ $proflg -gt 0 ];then
                PrtMsg "$line进程启动成功..." "$NORM" "$NORM"
            fi
        else 
            PrtMsg "$line非proc.list配置方式启动，请确认是否需要启动..." "$NORM" "$NORM"
        fi
    done
}

ProcHtSqlData(){
    PrtMsg "[${ARTFNM}]交易配置回退开始" "$BOLD" "$NORM"
    
    #将配置文件导向ARTFDATABAK备份目录
    export FDIR=${ARTFDATABAK}
    
    #交易配置回退
    sh ${ARTFSQLDATA}/${ARTFNO}i.sh
    
    PrtMsg "[${ARTFNM}]交易配置回退完成" "$BOLD" "$NORM"
}

ProcHtDiffCopy(){
    PrtMsg "[${ARTFNM}]配置文件回退开始" "$BOLD" "$NORM"
    
    #定义临时操作文件
    HtDiffCopy=${ARTFTMP}/HtDiffCopy.tm.${PID}
    
    #读取配置文件${ARTFDIFFCOPY}/diffcopy.list内容并组操作语句
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ -s '${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" ];then cp -p '${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" %s",$0)} {printf(";fi;\n")}' > ${HtDiffCopy}
    
    #执行回退操作
    sh ${HtDiffCopy}
    cat ${HtDiffCopy}
    rm -f ${HtDiffCopy}
    
    PrtMsg "[${ARTFNM}]配置文件回退完成" "$BOLD" "$NORM"
}

ProcHtSameCopy(){
    PrtMsg "[${ARTFNM}]可执行文件回退开始" "$BOLD" "$NORM"
    
    #定义临时操作文件
    HtSameCopy=${ARTFTMP}/HtSameCopy.tm.${PID}
    
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并组操作语句
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep -v "artfhuitui.sh" | awk -F '/' '{split($0,arr,"/")} {printf("if [ -s '${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" ];then cp -p '${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" %s;chmod 750 %s",$0,$0)} {printf(";fi;\n")}' > ${HtSameCopy}
    
    #判断是否需要停tuxedo服务
    ProcHtChkTux
    
    #判断是否需要停对应进程
    ProcHtChkPro
    
    #执行回退操作
    sh ${HtSameCopy}
    cat ${HtSameCopy}
    rm -f ${HtSameCopy}
    
    #启动回退进程
    #ProcHtUpPro
    
    #判断samecopy.list中是否完成artfhuitui.sh回退
    if [ `cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep "artfhuitui.sh" | wc -l` -ne 0 ];then
        PrtMsg "[artfhuanban.sh]请在任务完成后通过手工执行[cp -p ${ARTFDATABAK}/sbin/artfhuitui.sh ~/sbin/artfhuitui.sh]回退，任意键继续" "$BOLD" "$NORM"
        if [ "$REMOTE" != "true" ];then
            read
        fi
    fi
    
    PrtMsg "[${ARTFNM}]可执行文件回退完成" "$BOLD" "$NORM"
}

ProcHtDbOperate(){
    PrtMsg "[${ARTFNM}]数据库操作回退开始: " "$BOLD" "$NORM"
    
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
    
    PrtMsg "[${ARTFNM}]数据库操作回退结束: " "$BOLD" "$NORM"
}

ProcHtSqlData
ProcHtDiffCopy
ProcHtSameCopy
ProcHtDbOperate "$RUNDBNAME" "${ARTFDBOPERATE}/rundbhuitui.sql"
ProcHtDbOperate "$CFGDBNAME" "${ARTFDBOPERATE}/cfgdbhuitui.sql"

PrtMsg "\n[${ARTFNM}]回退结束...\n" "$BOLD" "$NORM"
