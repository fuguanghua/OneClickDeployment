#!/bin/sh
##############################################################
#  Create for : artfremote.sh                                #
#  Create on  : 2017-01-01                                   #
#  System of  : HP-UNIX                                      #
##############################################################
PID=$$

#����Ŀ¼
ARTFTMP="$HOME/tmp/artf"
mkdir -p ${ARTFTMP}
artfcmdsh="${ARTFTMP}/artfcmd.tm.${PID}"
artfcmdrmt="${ARTFTMP}/artfcmdrmt.tm.${PID}"
artfremote="${ARTFTMP}/artfremote.tm.${PID}"

#�����ӡ��ʽ
NORM="\033[0m"
BOLD="\033[1m"
BLNK="\033[5m"
HIGH="\033[7m"

#��ӡ����
PrtMsg()
{
    mesg=$1
    head=$2
    tail=$3

    echo "${head}${mesg}${tail}"
}

#��ȡIPLIST����
GetIpList()
{
    hostflg=`echo $HOSTNMID | sed 's/[0-9.]//g'`
    if [ "$hostflg" = "kf" ] || [ "$hostflg" = "sit" ];then      
        cat ~/etc/ftpcli.ini | grep -vE "^$|^#|10.240.93.110|10.240.94.147" | grep -E "10.240.94.208|10.240.94.209"
    else
        cat ~/etc/ftpcli.ini | grep -vE "^$|^#|10.240.93.110|10.240.94.147"
    fi
}


#�ش�IP��ַ
netstat -in | grep -vE "Address|127.0.0.1" | awk '{print $4}' | while read ipline
do
    if [ `cat ~/etc/ftpcli.ini | grep "$ipline" | wc -l` -ne 0 ];then
        clientip=$ipline
    fi
done
if [ "x$clientip" = "x" ];then
    echo "δ��ȡ������IP��ַ"
    exit 0
fi
#�ش��˿�
clientport=`cat ~/etc/ftpsvr.ini | grep -v "^$" | grep -v "^#" | grep "PORT=" | sed 's/PORT=//g'`

#����ѡ����Ÿ�ʽ
PS3="��� => " ; export PS3

#��ȡ��ǰĿ¼�Ļ����
PrtMsg "��ѡ����Ҫ�����Ļ�������" "$BOLD" "$NORM"
select tarnm in `ls -F $PWD | grep -E "^artf([0-9]{3,8}).tar$|^artfall.tar$"`
do
    PrtMsg "�����Ϊ��$tarnm" "$NORM" "$NORM"
    break
done
if [ "x$tarnm" = "x" ];then
    PrtMsg "û�л����" "$NORM" "$NORM"
    exit 0
fi

PrtMsg "\n��ѡ����Ҫ������Զ�̷�������ַ���(multi:��ѡ all:ȫ��)" "$BOLD" "$NORM"
select opt in `GetIpList` multi all
do
    #echo $ipport
    if [ "$opt" =  "all" ];then
        ipport=$opt
        echo $ipport
        break
    elif [ "$opt" =  "multi" ] && [ "$MULTI" != "true" ];then
        export MULTI="true"
        PrtMsg "��ѡ���IP��ַ��ȷ�Ϻ�ѡmultiѡ���˳�" "$NORM" "$NORM"
    elif [ "$opt" =  "multi" ] && [ "$MULTI" = "true" ];then
        break
    else
        if [ "$MULTI" = "true" ];then
            if [ `echo "$ipport" | grep "$opt" | wc -l` -eq 0 ];then
                ipport="$ipport $opt"
                echo $ipport
            else
                PrtMsg "$opt�ظ�" "$NORM" "$NORM"
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
    PrtMsg "û�п��õĵ�ַ��Ϣ" "$NORM" "$NORM"
    exit 0
fi
PrtMsg "��ѡ��ĵ�ַΪ:$ipport" "$NORM" "$NORM"

PrtMsg "\n��ѡ����Ҫ�����Ĳ������" "$BOLD" "$NORM"
select operate in "����&����" "����" "����" "����" "����&����(������)" "����(������)" "����(������)"
do
    PrtMsg "ѡ��Ĳ���Ϊ��$operate" "$NORM" "$NORM"
    break
done
if [ "x$operate" = "x" ];then
    PrtMsg "�������" "$NORM" "$NORM"
    exit 0
fi
if [ `echo $operate | grep "������" | wc -l` -ne 0 ];then
    PrtMsg "\n������[����/����]ǰҪִ������(����ֹͣӦ������bosdown�ȣ���������÷ֺ�;�ֿ�)" "$BOLD" "$NORM"
    read inputstop?
    PrtMsg "\n������[����/����]��Ҫִ������(��������Ӧ������bosup��bosload�ȣ���������÷ֺ�;�ֿ�)" "$BOLD" "$NORM"
    read inputstart?
fi

#����ֺ�У��
if [ "x$inputstart" != "x" ];then
    inputstart=`echo $inputstart|sed 's/$/;/'`
fi
if [ "x$inputstop" != "x" ];then
    inputstop=`echo $inputstop|sed 's/$/;/'`
fi

unset OPSTR1
unset OPSTR2
#���������
ARTFNO=`echo $tarnm | sed 's/.tar//g'`
if [ `echo $operate | grep "����" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} sh ./beifen.sh;"
    OPSTR2="${OPSTR2} artfbeifen.sh ${ARTFNO} 2>&1 > ${ARTFNO}.beifen.log;"
fi
if [ `echo $operate | grep "����" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} $inputstop sh ./huanban.sh; $inputstart"
    OPSTR2="${OPSTR2} $inputstop artfhuanban.sh ${ARTFNO} 2>&1 > ${ARTFNO}.huanban.log; $inputstart"
fi
if [ `echo $operate | grep "����" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} $inputstop sh ./huitui.sh; $inputstart"
    OPSTR2="${OPSTR2} $inputstop artfhuitui.sh ${ARTFNO} 2>&1 > ${ARTFNO}.huitui.log; $inputstart"
fi
#����ֺ�У��,��������ֺ��滻Ϊһ������ȥ��ĩβ�ֺ�
OPSTR1=`echo ${OPSTR1} | sed 's/[;][;]*/;/g' | sed 's/;$//g'`
OPSTR2=`echo ${OPSTR2} | sed 's/[;][;]*/;/g' | sed 's/;$//g'`
#echo OPSTR1:${OPSTR1}
#echo OPSTR2:${OPSTR2}

PrtMsg "\n�����뻻������(���Զ�����~/install/�µ�����Ŀ¼��ֱ�ӻس��򴴽�����Ŀ¼)" "$BOLD" "$NORM"
read inputdate?
if [ "x$inputdate" != "x" ];then
    if [ `echo $inputdate | grep "20[0-9][0-9][0-1][0-9][0-3][0-9]" | wc -l` -ne 0 ];then
        REMOTEINSTALLDIR='~/install/'"$inputdate"''
        PrtMsg "Զ�̻���ʹ��ָ������:$REMOTEINSTALLDIR" "$NORM" "$NORM"
    else
        REMOTEINSTALLDIR='~/install/'"`date +%Y%m%d`"''
        PrtMsg "Զ�̻���ʹ�õ�������:$REMOTEINSTALLDIR" "$NORM" "$NORM"
    fi
else
    REMOTEINSTALLDIR='~/install/'"`date +%Y%m%d`"''
    PrtMsg "Զ�̻���ʹ�õ�������:$REMOTEINSTALLDIR" "$NORM" "$NORM"
fi
#����ʹ��Զ�̻���ʱ���жϻ���Ŀ¼�뵱ǰĿ¼�Ƿ�һ��
LOCALINSTALLDIR=`echo "$REMOTEINSTALLDIR" | sed 's/~//g'`
LOCALINSTALLFLG=`echo "$PWD" | grep "$LOCALINSTALLDIR" | wc -l`
#echo $LOCALINSTALLFLG

PrtMsg "\n��ȷ���Ƿ����Զ�̻������(y/n)?" "$BOLD" "$NORM"
read input?
case $input in
Y|y)
    break
    ;;
*)
    PrtMsg "��ֹ���л���" "$NORM" "$NORM"
    exit 0
    ;;
esac



#�ж��Ƿ�һ�������
if [ "$tarnm" = "artfall.tar" ];then
    #һ�������
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
        echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/beifen.log '"$REMOTEINSTALLDIR"'/beifen.log 2>&1 1>/dev/null' >> ${artfcmdsh}
    fi
    if [ `echo ${OPSTR1} | grep "huanban.sh" | wc -l` -ne 0 ];then
        echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/huanban.log '"$REMOTEINSTALLDIR"'/huanban.log 2>&1 1>/dev/null' >> ${artfcmdsh}
    fi
    if [ `echo ${OPSTR1} | grep "huitui.sh" | wc -l` -ne 0 ];then
        echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/huitui.log '"$REMOTEINSTALLDIR"'/huitui.log 2>&1 1>/dev/null' >> ${artfcmdsh}
    fi
    echo 'fi' >> ${artfcmdsh}
    
else
    #���������
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
        echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.beifen.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.beifen.log 2>&1 1>/dev/null' >> ${artfcmdsh}
    fi
    if [ `echo ${OPSTR2} | grep "huanban.sh" | wc -l` -ne 0 ];then
        echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.huanban.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.huanban.log 2>&1 1>/dev/null' >> ${artfcmdsh}
    fi
    if [ `echo ${OPSTR2} | grep "huitui.sh" | wc -l` -ne 0 ];then
        echo '    ftpcli '"$clientip"' '"$clientport"' 0 3 '"$PWD"'/log/'"$ARTFNO"'.huitui.log '"$REMOTEINSTALLDIR"'/'"$ARTFNO"'.huitui.log 2>&1 1>/dev/null' >> ${artfcmdsh}
    fi
    echo 'fi' >> ${artfcmdsh}
    
fi

PrtMsg "\n��ʼִ��Զ�̻���:" "$BOLD" "$NORM"

>${artfremote}
#ѭ������Զ�̷�����
if [ "$ipport" = "all" ];then
    #���е�IP��ַ
    for iplist in `GetIpList`
    do
        IPADDR=`echo $iplist | awk -F ':' '{print $1}'`
        PORTNO=`echo $iplist | awk -F ':' '{print $2}'`
        if [ $LOCALINSTALLFLG -ne 0 ] && [ "$IPADDR" = "$clientip" ];then
            echo "printf \"$IPADDR ������Ѵ���,���贫��:\n\"" >> ${artfremote}
        else
            echo "printf \"$IPADDR ���������:\"" >> ${artfremote}
            echo ftpcli $IPADDR $PORTNO 0 0 "$REMOTEINSTALLDIR/$tarnm" "$PWD/$tarnm" >> ${artfremote}
        fi
        echo "printf \"$IPADDR �ű�����:\"" >> ${artfremote}
        echo ftpcli $IPADDR $PORTNO 0 2 ${artfcmdrmt} ${artfcmdsh} >> ${artfremote}
    done
elif [ "$MULTI" = "true" ];then
    #��ѡ��IP��ַ
    for iplist in $ipport
    do
        IPADDR=`echo $iplist | awk -F ':' '{print $1}'`
        PORTNO=`echo $iplist | awk -F ':' '{print $2}'`
        if [ $LOCALINSTALLFLG -ne 0 ] && [ "$IPADDR" = "$clientip" ];then
            echo "printf \"$IPADDR ������Ѵ���,���贫��:\n\"" >> ${artfremote}
        else
            echo "printf \"$IPADDR ���������:\"" >> ${artfremote}
            echo ftpcli $IPADDR $PORTNO 0 0 "$REMOTEINSTALLDIR/$tarnm" "$PWD/$tarnm" >> ${artfremote}
        fi
        echo "printf \"$IPADDR �ű�����:\"" >> ${artfremote}
        echo ftpcli $IPADDR $PORTNO 0 2 ${artfcmdrmt} ${artfcmdsh} >> ${artfremote}
    done
else
    #����IP��ַ
    IPADDR=`echo $ipport | awk -F ':' '{print $1}'`
    PORTNO=`echo $ipport | awk -F ':' '{print $2}'`
    if [ $LOCALINSTALLFLG -ne 0 ] && [ "$IPADDR" = "$clientip" ];then
        echo "printf \"$IPADDR ������Ѵ���,���贫��:\n\"" >> ${artfremote}
    else
        echo "printf \"$IPADDR ���������:\"" >> ${artfremote}
        echo ftpcli $IPADDR $PORTNO 0 0 "$REMOTEINSTALLDIR/$tarnm" "$PWD/$tarnm" >> ${artfremote}
    fi
    echo "printf \"$IPADDR �ű�����:\"" >> ${artfremote}
    echo ftpcli $IPADDR $PORTNO 0 2 ${artfcmdrmt} ${artfcmdsh} >> ${artfremote}
fi

sh ${artfremote}
rm -f ${artfremote}
rm -f ${artfcmdsh}

PrtMsg "\nԶ�̻�������У��Ժ���鿴$PWD/log/Ŀ¼�µĻ�����־:" "$BOLD" "$NORM"
unset MULTI
