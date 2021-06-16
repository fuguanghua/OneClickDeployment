##############################################################
#  Create for : artfremote.sh                                #
#  Create by  : weiqs                                        #
#  Create on  : 2017-01-01                                   #
#  Create at  : Bank of ShangHai                             #
#  System of  : RedHat                                       #
##############################################################
PID=$$

ARTFFLG='artf([0-9]{3,8})([0-9a-z_.]{0,9})|^BH_([A-Za-z0-9_.]{3,30})$'

#定义目录
ARTFTMP="$HOME/tmp/artf"
mkdir -p ${ARTFTMP}
artfcmdsh="${ARTFTMP}/artfcmd.tm.${PID}"
artfcmdrmt="${ARTFTMP}/artfcmdrmt.tm.${PID}"
artfremote="${ARTFTMP}/artfremote.tm.${PID}"

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

#获取IPLIST集合
GetIpList()
{
    hostflg=`echo $HOSTNMID | sed 's/[0-9.]//g'`
    if [ "$hostflg" = "DEV" ] || [ "$hostflg" = "SIT" ];then      
        cat ~/bin/etc/ftpcli.ini | grep -vE "^$|^#|10.240.41.66|10.240.44.218"
    else
        cat ~/bin/etc/ftpcli.ini | grep -vE "^$|^#|10.240.41.66|10.240.44.218"
    fi
}


#回传IP地址
ipline=`ifconfig | grep "inet addr:" | grep -v "127.0.0.1" | awk '{print $2}' | awk -F ':' '{print $2}'`
if [ `cat ~/bin/etc/ftpcli.ini | grep "$ipline" | wc -l` -ne 0 ];then
    clientip=$ipline
fi
clientip=$ipline
if [ "x$clientip" = "x" ];then
    echo "未获取到本机IP地址"
    exit 0
fi
#回传端口
clientport=`cat ~/bin/etc/ftpsvr.ini | grep -v "^$" | grep -v "^#" | grep "PORT=" | sed 's/PORT=//g'`

#定义选择序号格式
PS3="序号 => " ; export PS3

#获取当前目录的换版包
PrtMsg "请选择你要操作的换版包序号" "$BOLD" "$NORM"
select tarnm in `ls -F $PWD|grep ".tar"|grep -E "${ARTFFLG}|^artfall.tar$"`
do
    PrtMsg "换版包为：$tarnm" "$NORM" "$NORM"
    break
done
if [ "x$tarnm" = "x" ];then
    PrtMsg "没有换版包" "$NORM" "$NORM"
    exit 0
fi

PrtMsg "\n请选择你要操作的远程服务器地址序号(multi:多选 all:全部)" "$BOLD" "$NORM"
select opt in `GetIpList` multi all
do
    #echo $ipport
    if [ "$opt" =  "all" ];then
        ipport=$opt
        echo $ipport
        break
    elif [ "$opt" =  "multi" ] && [ "$MULTI" != "true" ];then
        export MULTI="true"
        PrtMsg "请选多个IP地址，确认后选multi选项退出" "$NORM" "$NORM"
    elif [ "$opt" =  "multi" ] && [ "$MULTI" = "true" ];then
        break
    else
        if [ "$MULTI" = "true" ];then
            if [ `echo "$ipport" | grep "$opt" | wc -l` -eq 0 ];then
                ipport="$ipport $opt"
                echo $ipport
            else
                PrtMsg "$opt重复" "$NORM" "$NORM"
                continue
            fi
        else
            ipport=$opt
            echo $ipport
            break
        fi
    fi
done
if [ "x$ipport" = "x" ];then
    PrtMsg "没有可用的地址信息" "$NORM" "$NORM"
    exit 0
fi
PrtMsg "你选择的地址为:$ipport" "$NORM" "$NORM"

PrtMsg "\n请选择你要操作的步骤序号" "$BOLD" "$NORM"
select operate in "备份&换版" "备份" "换版" "回退" "备份&换版(含命令)" "换版(含命令)" "回退(含命令)"
do
    PrtMsg "选择的操作为：$operate" "$NORM" "$NORM"
    break
done
if [ "x$operate" = "x" ];then
    PrtMsg "步骤错误" "$NORM" "$NORM"
    exit 0
fi
if [ `echo $operate | grep "含命令" | wc -l` -ne 0 ];then
    PrtMsg "\n请输入[换版/回退]前要执行命令(比如停止应用命令bosdown等，多个命令用分号;分开)" "$BOLD" "$NORM"
    read inputstop
    PrtMsg "\n请输入[换版/回退]后要执行命令(比如启动应用命令bosup、bosload等，多个命令用分号;分开)" "$BOLD" "$NORM"
    read inputstart
fi

#命令分号校验
if [ "x$inputstart" != "x" ];then
    inputstart=`echo $inputstart|sed 's/$/;/'`
fi
if [ "x$inputstop" != "x" ];then
    inputstop=`echo $inputstop|sed 's/$/;/'`
fi

unset OPSTR1
unset OPSTR2
#组操作命令
ARTFNO=`echo $tarnm | sed 's/.tar//g'`
if [ `echo $operate | grep "备份" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} sh ./beifen.sh;"
    OPSTR2="${OPSTR2} artfbeifen.sh ${ARTFNO} 2>&1 > ${ARTFNO}.beifen.log;"
fi
if [ `echo $operate | grep "换版" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} $inputstop sh ./huanban.sh; $inputstart"
    OPSTR2="${OPSTR2} $inputstop artfhuanban.sh ${ARTFNO} 2>&1 > ${ARTFNO}.huanban.log; $inputstart"
fi
if [ `echo $operate | grep "回退" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} $inputstop sh ./huitui.sh; $inputstart"
    OPSTR2="${OPSTR2} $inputstop artfhuitui.sh ${ARTFNO} 2>&1 > ${ARTFNO}.huitui.log; $inputstart"
fi
#命令分号校验,多个连续分号替换为一个，并去除末尾分号
OPSTR1=`echo ${OPSTR1} | sed 's/[;][;]*/;/g' | sed 's/;$//g'`
OPSTR2=`echo ${OPSTR2} | sed 's/[;][;]*/;/g' | sed 's/;$//g'`
#echo OPSTR1:${OPSTR1}
#echo OPSTR2:${OPSTR2}

PrtMsg "\n请输入换版日期(可自动创建~/install/下的日期目录，直接回车则创建当天目录)" "$BOLD" "$NORM"
read inputdate
if [ "x$inputdate" != "x" ];then
    if [ `echo $inputdate | grep "20[0-9][0-9][0-1][0-9][0-3][0-9]" | wc -l` -ne 0 ];then
        REMOTEINSTALLDIR='~/install/'"$inputdate"''
        PrtMsg "远程换版使用指定日期:$REMOTEINSTALLDIR" "$NORM" "$NORM"
    else
        REMOTEINSTALLDIR='~/install/'"`date +%Y%m%d`"''
        PrtMsg "远程换版使用当天日期:$REMOTEINSTALLDIR" "$NORM" "$NORM"
    fi
else
    REMOTEINSTALLDIR='~/install/'"`date +%Y%m%d`"''
    PrtMsg "远程换版使用当天日期:$REMOTEINSTALLDIR" "$NORM" "$NORM"
fi
#本机使用远程换版时需判断换版目录与当前目录是否一样
LOCALINSTALLDIR=`echo "$REMOTEINSTALLDIR" | sed 's/~//g'`
LOCALINSTALLFLG=`echo "$PWD" | grep "$LOCALINSTALLDIR" | wc -l`
#echo $LOCALINSTALLFLG

PrtMsg "\n请确认是否进行远程换版操作(y/n)?" "$BOLD" "$NORM"
read input
case $input in
Y|y)
    #break
    ;;
*)
    PrtMsg "终止进行换版" "$NORM" "$NORM"
    exit 0
    ;;
esac



#判断是否一键换版包
if [ "$tarnm" = "artfall.tar" ];then
    #一键换版包
    >${artfcmdsh}
    echo 'cd '"$REMOTEINSTALLDIR"'' >> ${artfcmdsh}
    echo 'num=0' >> ${artfcmdsh}
    echo 'while [ $num -lt 600 ]' >> ${artfcmdsh}
    echo 'do' >> ${artfcmdsh}
    echo '    sleep 5' >> ${artfcmdsh}
    echo '    num=`expr $num + 1`' >> ${artfcmdsh}
    echo '    if [ `openssl md5 '"$tarnm"' | awk -F '"'"'[ =]'"'"' '"'"'{print $3}'"'"'` = '"`openssl md5 $tarnm | awk -F '[ =]' '{print $3}'`"' ];then' >> ${artfcmdsh}
    echo '        if [ `ps -fu $LOGNAME | grep -w "artfremote.sh" | wc -l` -eq 1 ];then' >> ${artfcmdsh}
    echo '            break;' >> ${artfcmdsh}
    echo '        fi' >> ${artfcmdsh}
    echo '    fi' >> ${artfcmdsh}
    echo 'done' >> ${artfcmdsh}
    echo 'if [ `openssl md5 '"$tarnm"' | awk -F '"'"'[ =]'"'"' '"'"'{print $3}'"'"'` = '"`openssl md5 $tarnm | awk -F '[ =]' '{print $3}'`"' ];then' >> ${artfcmdsh}
    echo '    sleep 5' >> ${artfcmdsh}
    echo '    tar xvf artfall.tar 2>&1 > beifen.log' >> ${artfcmdsh}
    echo '    export REMOTE=true' >> ${artfcmdsh}
    echo '    '"${OPSTR1}"'' >> ${artfcmdsh}
    if [ `echo ${OPSTR1} | grep "beifen.sh" | wc -l` -ne 0 ];then
        #echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/beifen.log '"$REMOTEINSTALLDIR"'/beifen.log 2>&1 1>/dev/null' >> ${artfcmdsh}
        echo '    retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/beifen.log '"$REMOTEINSTALLDIR"'/beifen.log `;loopnum=`expr ${loopnum} - 1`;sleep 0.5;done' >> ${artfcmdsh}
    fi
    if [ `echo ${OPSTR1} | grep "huanban.sh" | wc -l` -ne 0 ];then
        #echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/huanban.log '"$REMOTEINSTALLDIR"'/huanban.log 2>&1 1>/dev/null' >> ${artfcmdsh}
        echo '    retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/huanban.log '"$REMOTEINSTALLDIR"'/huanban.log `;loopnum=`expr ${loopnum} - 1`;sleep 0.5;done' >> ${artfcmdsh}
    fi
    if [ `echo ${OPSTR1} | grep "huitui.sh" | wc -l` -ne 0 ];then
        #echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/huitui.log '"$REMOTEINSTALLDIR"'/huitui.log 2>&1 1>/dev/null' >> ${artfcmdsh}
        echo '    retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/huitui.log '"$REMOTEINSTALLDIR"'/huitui.log `;loopnum=`expr ${loopnum} - 1`;sleep 0.5;done' >> ${artfcmdsh}
    fi
    echo 'fi' >> ${artfcmdsh}
    
else
    #单个任务包
    >${artfcmdsh}
    echo 'cd '"$REMOTEINSTALLDIR"'' >> ${artfcmdsh}
    echo 'num=0' >> ${artfcmdsh}
    echo 'while [ $num -lt 600 ]' >> ${artfcmdsh}
    echo 'do' >> ${artfcmdsh}
    echo '    sleep 5' >> ${artfcmdsh}
    echo '    num=`expr $num + 1`' >> ${artfcmdsh}
    echo '    if [ `openssl md5 '"$tarnm"' | awk -F '"'"'[ =]'"'"' '"'"'{print $3}'"'"'` = '"`openssl md5 $tarnm | awk -F '[ =]' '{print $3}'`"' ];then' >> ${artfcmdsh}
    echo '        if [ `ps -fu $LOGNAME | grep -w "artfremote.sh" | wc -l` -eq 1 ];then' >> ${artfcmdsh}
    echo '            break;' >> ${artfcmdsh}
    echo '        fi' >> ${artfcmdsh}
    echo '    fi' >> ${artfcmdsh}
    echo 'done' >> ${artfcmdsh}
    echo 'if [ `openssl md5 '"$tarnm"' | awk -F '"'"'[ =]'"'"' '"'"'{print $3}'"'"'` = '"`openssl md5 $tarnm | awk -F '[ =]' '{print $3}'`"' ];then' >> ${artfcmdsh}
    echo '    sleep 5' >> ${artfcmdsh}
    echo '    export REMOTE=true' >> ${artfcmdsh}
    echo '    '"${OPSTR2}"'' >> ${artfcmdsh}
    if [ `echo ${OPSTR2} | grep "beifen.sh" | wc -l` -ne 0 ];then
        #echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.beifen.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.beifen.log 2>&1 1>/dev/null' >> ${artfcmdsh}
        echo '    retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.beifen.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.beifen.log `;loopnum=`expr ${loopnum} - 1`;sleep 0.5;done' >> ${artfcmdsh}
    fi
    if [ `echo ${OPSTR2} | grep "huanban.sh" | wc -l` -ne 0 ];then
        #echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.huanban.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.huanban.log 2>&1 1>/dev/null' >> ${artfcmdsh}
        echo '    retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.huanban.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.huanban.log `;loopnum=`expr ${loopnum} - 1`;sleep 0.5;done' >> ${artfcmdsh} 
    fi
    if [ `echo ${OPSTR2} | grep "huitui.sh" | wc -l` -ne 0 ];then
        #echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.huitui.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.huitui.log 2>&1 1>/dev/null' >> ${artfcmdsh}
        echo '    retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.huitui.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.huitui.log `;loopnum=`expr ${loopnum} - 1`;sleep 0.5;done' >> ${artfcmdsh}  
    fi
    echo 'fi' >> ${artfcmdsh}
    
fi

PrtMsg "\n开始执行远程换版:" "$BOLD" "$NORM"

>${artfremote}
#循环处理远程服务器
if [ "$ipport" = "all" ];then
    #所有的IP地址
    for iplist in `GetIpList`
    do
        IPADDR=`echo $iplist | awk -F ':' '{print $1}'`
        PORTNO=`echo $iplist | awk -F ':' '{print $2}'`
        if [ $LOCALINSTALLFLG -ne 0 ] && [ "$IPADDR" = "$clientip" ];then
            echo "printf \"$IPADDR 换版包已存在,无需传输:\n\"" >> ${artfremote}
        else
            echo "printf \"$IPADDR 换版包传输:\"" >> ${artfremote}
            #echo ftpcli $IPADDR $PORTNO 0 0 "$REMOTEINSTALLDIR/$tarnm" "$PWD/$tarnm" >> ${artfremote}
            echo 'retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$IPADDR"' '"$PORTNO"' 0 0 '"$REMOTEINSTALLDIR"'/'"$tarnm"' '"$PWD"'/'"$tarnm"' `;loopnum=`expr ${loopnum} - 1`;echo ${retcode};sleep 0.1;done ' >> ${artfremote}
        fi
        echo "printf \"$IPADDR 脚本传输:\"" >> ${artfremote}
        #echo ftpcli $IPADDR $PORTNO 0 2 ${artfcmdrmt} ${artfcmdsh} >> ${artfremote}
        echo 'retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$IPADDR"' '"$PORTNO"' 0 2 '"${artfcmdrmt}"' '"${artfcmdsh}"' `;loopnum=`expr ${loopnum} - 1`;echo ${retcode};sleep 0.1;done ' >> ${artfremote}
    done
elif [ "$MULTI" = "true" ];then
    #多选的IP地址
    for iplist in $ipport
    do
        IPADDR=`echo $iplist | awk -F ':' '{print $1}'`
        PORTNO=`echo $iplist | awk -F ':' '{print $2}'`
        if [ $LOCALINSTALLFLG -ne 0 ] && [ "$IPADDR" = "$clientip" ];then
            echo "printf \"$IPADDR 换版包已存在,无需传输:\n\"" >> ${artfremote}
        else
            echo "printf \"$IPADDR 换版包传输:\"" >> ${artfremote}
            #echo ftpcli $IPADDR $PORTNO 0 0 "$REMOTEINSTALLDIR/$tarnm" "$PWD/$tarnm" >> ${artfremote}
            echo 'retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$IPADDR"' '"$PORTNO"' 0 0 '"$REMOTEINSTALLDIR"'/'"$tarnm"' '"$PWD"'/'"$tarnm"' `;loopnum=`expr ${loopnum} - 1`;echo ${retcode};sleep 0.1;done ' >> ${artfremote}
        fi
        echo "printf \"$IPADDR 脚本传输:\"" >> ${artfremote}
        #echo ftpcli $IPADDR $PORTNO 0 2 ${artfcmdrmt} ${artfcmdsh} >> ${artfremote}
        echo 'retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$IPADDR"' '"$PORTNO"' 0 2 '"${artfcmdrmt}"' '"${artfcmdsh}"' `;loopnum=`expr ${loopnum} - 1`;echo ${retcode};sleep 0.1;done ' >> ${artfremote}
    done
else
    #单个IP地址
    IPADDR=`echo $ipport | awk -F ':' '{print $1}'`
    PORTNO=`echo $ipport | awk -F ':' '{print $2}'`
    if [ $LOCALINSTALLFLG -ne 0 ] && [ "$IPADDR" = "$clientip" ];then
        echo "printf \"$IPADDR 换版包已存在,无需传输:\n\"" >> ${artfremote}
    else
        echo "printf \"$IPADDR 换版包传输:\"" >> ${artfremote}
        #echo ftpcli $IPADDR $PORTNO 0 0 "$REMOTEINSTALLDIR/$tarnm" "$PWD/$tarnm" >> ${artfremote}
        echo 'retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$IPADDR"' '"$PORTNO"' 0 0 '"$REMOTEINSTALLDIR"'/'"$tarnm"' '"$PWD"'/'"$tarnm"' `;loopnum=`expr ${loopnum} - 1`;echo ${retcode};sleep 0.1;done ' >> ${artfremote}
    fi
    echo "printf \"$IPADDR 脚本传输:\"" >> ${artfremote}
    #echo ftpcli $IPADDR $PORTNO 0 2 ${artfcmdrmt} ${artfcmdsh} >> ${artfremote}
    echo 'retcode=0;loopnum=3;while [ "${retcode}" != "RET=[0]" ] && [ ${loopnum} -gt 0 ];do retcode=`ftpcli '"$IPADDR"' '"$PORTNO"' 0 2 '"${artfcmdrmt}"' '"${artfcmdsh}"' `;loopnum=`expr ${loopnum} - 1`;echo ${retcode};sleep 0.1;done ' >> ${artfremote}
fi

sh ${artfremote}
rm -f ${artfremote}
rm -f ${artfcmdsh}

PrtMsg "\n远程换版进行中，稍后请查看$PWD/log/目录下的回盘日志:" "$BOLD" "$NORM"
unset MULTI
