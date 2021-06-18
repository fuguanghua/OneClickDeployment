#!/bin/sh
##############################################################
#  Create for : artfhuanban.sh                               #
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
DIFFRST=${ARTFTMP}/diffrst.rst.${PID}

#清理30分钟前过期文件
CleanTmpTOU(){
    DELDIR=$1
    perl -e 'my $dir="'"$DELDIR"'";opendir DH,$dir or die "cannot chdir to $dir : $!";for my $file(readdir DH){my $fpath=$dir."/".$file;if(((time()-(stat($fpath))[10])>1800)&&($fpath =~ /artf/)){unlink $fpath;}}closedir DH;'
}
CleanTmpTOU "${ARTFTMP}"

#换版目录未解压，则解压
if [ ! -d ${ARTFDIR} ];then
    echo "${ARTFDIR}目录不存在"
    tar xvf ${ARTFNM}.tar 2>&1 1>/dev/null
fi
#如果重复换版，则重新解压
if [ -s ${PWDDIR}/break.txt ];then
    tarflg=`cat ${PWDDIR}/break.txt | grep "${ARTFNO}" | wc -l`
else
    tarflg=0
fi
if [ -d ${ARTFDIR} ] && [ ${tarflg} -ne 0 ];then
    echo "${ARTFDIR}重新解压"
    #mv ${ARTFDIR} ${ARTFDIR}.bak.`date +'%m%d%H%M%S'`
    tar xvf ${ARTFNM}.tar 2>&1 1>/dev/null
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
PrtMsg "\n[${ARTFNM}]换版开始...\n" "$BOLD" "$NORM"

OperateDB()
{
    DBNM=$1
    File=$2
    Ret=$3
    dbaccess ${DBNM} < ${File} 2>&1
    eval ${Ret}=$?
}

DiffChk(){
    #读取配置文件${ARTFDIFFCOPY}/diffcopy.list并和原文件进行比对
    while true
    do
        >${DIFFRST}
        cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("'${HOME}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" '${ARTFDIFFCOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(".'${HOSTNMID}'")}  {printf("\n")}' | while read diffline;
        do
            oldname=`echo $diffline | awk '{print($1)}'`
            newname=`echo $diffline | awk '{print($2)}'`

            if [ -s $oldname ];then
                diff $diffline | grep -E "^<|^>" | awk '{if($0~/^> /) {gsub("^> ", "'$newname'新增内容:");} else if($0~/^< /) {gsub("^< ", "'$newname'缺少内容:");} printf($0"\n")}' >> ${DIFFRST}
            fi
        done
        if [ -s ${DIFFRST} ];then
            cat ${DIFFRST} | awk -F ':' '{if($1~/缺少内容/) printf("\033[7m"$0"\033[0m\n");else printf($0"\n");}'
            if [ `cat ${DIFFRST} | grep "缺少内容" | wc -l` -gt 0 ] && [ "$REMOTE" != "true" ];then
                PrtMsg "[${ARTFNM}]缺少配置内容" "$BOLD" "$NORM"
                PrtMsg "*************************" "$BOLD" "$NORM"
                PrtMsg " y)忽略检查             *" "$BOLD" "$NORM"
                PrtMsg " c)重新检查             *" "$BOLD" "$NORM"
                PrtMsg " *)其他健终止换版退出   *" "$BOLD" "$NORM"
                PrtMsg "*************************" "$BOLD" "$NORM"
                read anser?
                case $anser in
                Y|y)
                    PrtMsg "你输入的是[$anser],忽略提示,继续换版..." "$NORM" "$NORM"
                    break
                    ;;
                C|c)
                    PrtMsg "你输入的是[$anser],重新检查..." "$NORM" "$NORM"
                    continue
                    ;;
                *)
                    PrtMsg "你输入的是[$anser],暂停换版..." "$NORM" "$NORM"
                    exit 0
                    ;;
                esac
            else
                break
            fi
        else
            break
        fi
    done
    rm ${DIFFRST}
}

ProcHbChkTux(){
    #通过diffcopy.list匹配ubbconfig和dmconfig判断是否需要停止tuxedo服务
    tuxdmflg=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "dmconfig" | wc -l`
    tuxubbflg=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "ubbconfig" | wc -l`

    if [ $tuxdmflg -gt 0 ];then
        #判断BBL是否运行中
        tuxpro=`ps -u "$LOGNAME" | grep -v "grep" | grep -w "BBL" | wc -l`
        while [ $tuxpro -gt 0 ];do
            PrtMsg "tuxedo未停止,请全停应用,10秒后重新检测..." "$NORM" "$NORM"
            tuxpro=`ps -u "$LOGNAME" | grep -v "grep" | grep -w "BBL" | wc -l`
            sleep 10
        done
        
        PrtMsg "[${ARTFNM}]dmconfig编译开始" "$BOLD" "$NORM"
        
        tuxdmnm=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" |  grep "dmconfig" | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}'`
        dmloadcf -y "${HOME}$tuxdmnm"
        ls -lrt "${HOME}/etc/bdmconfig"
        
        PrtMsg "[${ARTFNM}]dmconfig编译完成" "$BOLD" "$NORM"
    fi

    if [ $tuxubbflg -gt 0 ];then
        #判断BBL是否运行中
        tuxpro=`ps -u "$LOGNAME" | grep -v "grep" | grep -w "BBL" | wc -l`
        while [ $tuxpro -gt 0 ];do
            PrtMsg "tuxedo未停止,请全停应用,10秒后重新检测..." "$NORM" "$NORM"
            tuxpro=`ps -u "$LOGNAME" | grep -v "grep" | grep -w "BBL" | wc -l`
            sleep 10
        done
        
        PrtMsg "[${ARTFNM}]ubbconfig编译开始" "$BOLD" "$NORM"
        
        tuxubbnm=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "ubbconfig" | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}'`
        tmloadcf -y "${HOME}$tuxubbnm"
        ls -lrt "${HOME}/etc/tuxconfig"
        
        PrtMsg "[${ARTFNM}]ubbconfig编译完成" "$BOLD" "$NORM"
    fi
}

ProcHbChkPro(){
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并检查进程是否存在
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | grep -v "artfhuanban.sh" | awk -F '/' '{split($0,arr,"/")} {printf("%s\n",arr[NF])}' \
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
                PrtMsg "正在通过${Shut}停$line进程..." "$NORM" "$NORM"
                ${Shut}
            else
                PrtMsg "非proc.list中配置的停进程操作，请手工停止..." "$NORM" "$NORM"
            fi
            
            proflg=`ps -fu "$LOGNAME" | grep -v "grep" | grep -w "$line" | wc -l`
            if [ $proflg -eq 0 ];then
                PrtMsg "$line进程已停止..." "$NORM" "$NORM"
                continue
            else
                PrtMsg "$line进程未停止，10秒后继续检测..." "$NORM" "$NORM"
            fi
            sleep 10
        done
    done
}

ProcHbUpPro(){
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并检查是否需要启进程
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | grep -v "artfhuanban.sh" | awk -F '/' '{split($0,arr,"/")} {printf("%s\n",arr[NF])}' \
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
            PrtMsg "$line非proc.list配置方式启动，请确认是否需要启动..." "$BOLD" "$NORM"
        fi
    done
}

ProcBreakHb(){
    #断点换版
    
    #第一个参数为子目录，第二个参数为执行文件名
    SubDir=$1
    FileNm=$2
    #echo "SubDir:$SubDir FileNm:$FileNm"
    
    HbBreak=${ARTFTMP}/HbBreak.tm.${PID}
    if [ ! -s ${PWDDIR}/break.txt ];then
        touch ${PWDDIR}/break.txt
    fi

    >${HbBreak}
    cat $FileNm | grep -v "^#" | grep -v "^$" | while read lineshell
    do
        if [ `cat ${PWDDIR}/break.txt | grep "${ARTFNM}|${SubDir}|succ|$lineshell" | wc -l` -eq 0 ];then
            echo "$lineshell" | tee -a ${HbBreak}
            echo "if [ \$? -eq 0 ];then" >> ${HbBreak}
            echo "    echo \"${ARTFNM}|${SubDir}|succ|$lineshell\" >> ${PWDDIR}/break.txt" >> ${HbBreak}
            echo "else" >> ${HbBreak}
            echo "    echo \"[$lineshell]\033[5m执行失败\033[0m\" " >> ${HbBreak}
            echo "fi" >> ${HbBreak}
        else
            PrtMsg "[$lineshell]已完成，忽略执行..." "$NORM" "$NORM"
        fi
    done
    sh ${HbBreak}
    rm -f ${HbBreak}
}

ProcHbSqlData(){
    PrtMsg "[${ARTFNM}]交易配置换版开始" "$BOLD" "$NORM"
    
    #将配置文件导向ARTFSQLDATA换版目录
    export FDIR=${ARTFSQLDATA}
    
    #判断导入数据目录是否需根据不同环境区分
    if [ "x$HOSTNMID" != "x" ];then
        for Sqldiff in `ls -F ${ARTFSQLDATA} | grep "/$" | sed 's/\///g' | grep "${HOSTNMID}"`
        do
            #echo "Sqldiff:${ARTFSQLDATA}/$Sqldiff"
            Sqldir=`echo $Sqldiff | sed "s/.${HOSTNMID}//g"`
            #echo "Sqldir:$Sqldir Sqldiff:$Sqldiff"
            if [ "x$Sqldir" != "x" ];then
                rm -rf ${ARTFSQLDATA}/$Sqldir
                cp -R ${ARTFSQLDATA}/$Sqldiff ${ARTFSQLDATA}/$Sqldir
            fi
        done
    fi
    
    #交易配置换版
    ProcBreakHb "sqldata" "${ARTFSQLDATA}/${ARTFNO}i.sh"
    
    PrtMsg "[${ARTFNM}]交易配置换版完成" "$BOLD" "$NORM"
}

ProcHbDiffCopy(){
    PrtMsg "[${ARTFNM}]配置文件换版开始" "$BOLD" "$NORM"
    
    #检查配置文件是否遗漏基线版本内容
    DiffChk
    
    #定义临时操作文件
    HbDiffCopy=${ARTFTMP}/HbDiffCopy.tm.${PID}
    
    #读取配置文件${ARTFDIFFCOPY}/diffcopy.list内容并组操作语句
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("cp -p '${ARTFDIFFCOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(".'${HOSTNMID}' '${HOME}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";\n")}' > ${HbDiffCopy}
    
    #执行换版操作
    ProcBreakHb "diffcopy" "${HbDiffCopy}"
    rm -f ${HbDiffCopy}
    
    PrtMsg "[${ARTFNM}]配置文件换版完成" "$BOLD" "$NORM"
}

ProcHbSameCopy(){
    PrtMsg "[${ARTFNM}]可执行文件换版开始" "$BOLD" "$NORM"
    
    #定义临时操作文件
    HbSameCopy=${ARTFTMP}/HbSameCopy.tm.${PID}
    
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并组操作语句
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | grep -v "artfhuanban.sh" | awk -F '/' '{split($0,arr,"/")} {printf("cp -p '${ARTFSAMECOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" '${HOME}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";chmod 750 '${HOME}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";\n")}' > ${HbSameCopy}
    
    #判断是否需要停tuxedo服务
    ProcHbChkTux
    
    #判断是否需要停对应进程
    ProcHbChkPro
    
    #执行换版操作
    ProcBreakHb "samecopy" "${HbSameCopy}"
    rm -f ${HbSameCopy}
    
    #启动换版进程
    #ProcHbUpPro
    
    #判断samecopy.list中是否完成artfhuanban.sh换版
    if [ `cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep "artfhuanban.sh" | wc -l` -ne 0 ];then
        HbSbinCopy=${ARTFTMP}/HbSbinCopy.tm
        >${HbSbinCopy}
        echo "while [ true ]" >>${HbSbinCopy}
        echo "do" >>${HbSbinCopy}
        echo "    if [ "'`ps -fu $LOGNAME | grep -v grep | grep artfhuanban.sh | wc -l`'" -eq 0 ];then" >>${HbSbinCopy}
        echo "        cp -p ${ARTFSAMECOPY}/sbin/artfhuanban.sh ~/sbin/artfhuanban.sh" >>${HbSbinCopy}
        echo "        chmod 750 ~/sbin/artfhuanban.sh" >>${HbSbinCopy}
        echo "        break" >>${HbSbinCopy}
        echo "    else" >>${HbSbinCopy}
        echo "        sleep 1" >>${HbSbinCopy}
        echo "    fi" >>${HbSbinCopy}
        echo "done" >>${HbSbinCopy}
        sh ${HbSbinCopy} &
    fi
    
    PrtMsg "[${ARTFNM}]可执行文件换版完成" "$BOLD" "$NORM"
}

ProcHbDbOperate(){
    PrtMsg "[${ARTFNM}]数据库操作换版开始: " "$BOLD" "$NORM"
    
    DBNAME=$1
    filesql=$2
    
    cd ${ARTFDBOPERATE}
    if [ `cat ${PWDDIR}/break.txt | grep "${ARTFNM}|dboperate|succ|$filesql" | wc -l` -eq 0 ];then
        if [ `cat $filesql | grep -v "^--" | grep -v "^$" | wc -l` -ne 0 ];then
            cat $filesql | grep -v "^--" | grep -v "^$"
            OperateDB "$DBNAME" "$filesql" "Ret"
            if [ ${Ret} -ne "0" ]
            then
                echo "[$filesql]数据库操作失败"
            else
                echo "${ARTFNM}|dboperate|succ|$filesql" >> ${PWDDIR}/break.txt
            fi
        fi
    else
        PrtMsg "[$filesql]已完成，忽略执行..." "$NORM" "$NORM"
    fi
    cd -
    
    PrtMsg "[${ARTFNM}]数据库操作换版结束: " "$BOLD" "$NORM"
}

ProcBreakDel(){
    #判断是否需要删除断点文件
    if [ ! -s ${PWDDIR}/break.txt ];then
        touch ${PWDDIR}/break.txt
    fi
    bknum=`cat ${PWDDIR}/break.txt | grep "^$ARTFNM|" | wc -l`
    if [ $bknum -ne 0 ];then
        if [ "$REMOTE" = "true" ];then
            cat ${PWDDIR}/break.txt | grep -v "^$ARTFNM|" > ${PWDDIR}/break.txt.tm
            mv ${PWDDIR}/break.txt.tm ${PWDDIR}/break.txt
        else
            read input?"是否清除断点文件break.txt中[$ARTFNM]换版成功记录，重新换版[y/n]？"
            case $input in
            Y|y)
                cat ${PWDDIR}/break.txt | grep -v "^$ARTFNM|" > ${PWDDIR}/break.txt.tm
                mv ${PWDDIR}/break.txt.tm ${PWDDIR}/break.txt
                ;;
            *)
                echo " "
                ;;
            esac
        fi
    fi
}

ProcBreakDel
ProcHbSqlData
ProcHbDiffCopy
ProcHbSameCopy
ProcHbDbOperate "$RUNDBNAME" "${ARTFDBOPERATE}/rundbhuanban.sql"
ProcHbDbOperate "$CFGDBNAME" "${ARTFDBOPERATE}/cfgdbhuanban.sql"

PrtMsg "\n[${ARTFNM}]换版完成...\n" "$BOLD" "$NORM"
