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
    echo "������artf�汾���,��: artf12345"
    exit 0
}

isatrf=`echo $1 | grep -E 'artf([0-9]{3,8})$' | wc -l`
if [ $isatrf -eq 0 ];then
    echo "������artf��ŷǷ�"
    exit 0
fi

#artf���
ARTFNM=$1

#��ȡartf��
ARTFNO=`echo ${ARTFNM} | sed 's/\/$//' | awk -F '/' '{print $NF}' | sed 's/artf//g'`
#echo ${ARTFNO}

#�������Ŀ¼
PWDDIR=`pwd`
ARTFDIR=${PWDDIR}/${ARTFNM}
ARTFDATABAK=${ARTFDIR}/databak
ARTFDIFFCOPY=${ARTFDIR}/diffcopy
ARTFSAMECOPY=${ARTFDIR}/samecopy
ARTFSQLDATA=${ARTFDIR}/sqldata
ARTFDBOPERATE=${ARTFDIR}/dboperate
ARTFTMP="$HOME/tmp/artf"
mkdir -p ${ARTFTMP}

#�ж��Ƿ��Ѵ���artfĿ¼
if [ ! -d ${ARTFDIR} ];then
    echo "${ARTFDIR}Ŀ¼������"
    exit 0
fi

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

#��ӡִ����Ϣ
PrtMsg "\n[${ARTFNM}]���˿�ʼ...\n" "$BOLD" "$NORM"

OperateDB()
{
    DBNM=$1
    File=$2
    Ret=$3
    dbaccess ${DBNM} < ${File} 2>&1
    eval ${Ret}=$?
}

ProcHtChkTux(){
    #ͨ��diffcopy.listƥ��ubbconfig��dmconfig�ж��Ƿ���Ҫֹͣtuxedo����
    tuxdmflg=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "dmconfig" | wc -l`
    tuxubbflg=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "ubbconfig" | wc -l`

    if [ $tuxdmflg -gt 0 ];then
        #�ж�BBL�Ƿ�������
        tuxpro=`ps -u "$LOGNAME" | grep -w "BBL" | wc -l`
        while [ $tuxpro -gt 0 ];do
            PrtMsg "tuxedoδֹͣ,��ȫͣӦ��,10������¼��..." "$NORM" "$NORM"
            tuxpro=`ps -u "$LOGNAME" | grep -w "BBL" | wc -l`
            sleep 10
        done
        
        PrtMsg "[${ARTFNM}]dmconfig���뿪ʼ" "$BOLD" "$NORM"
        
        tuxdmnm=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "dmconfig" | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}'`
        dmloadcf -y "${HOME}$tuxdmnm"
        ls -lrt "${HOME}/etc/bdmconfig"
        
        PrtMsg "[${ARTFNM}]dmconfig�������" "$BOLD" "$NORM"
    fi

    if [ $tuxubbflg -gt 0 ];then
        #�ж�BBL�Ƿ�������
        tuxpro=`ps -u "$LOGNAME" | grep -w "BBL" | wc -l`
        while [ $tuxpro -gt 0 ];do
            PrtMsg "tuxedoδֹͣ,��ȫͣӦ��,10������¼��..." "$NORM" "$NORM"
            tuxpro=`ps -u "$LOGNAME" | grep -w "BBL" | wc -l`
            sleep 10
        done
        
        PrtMsg "[${ARTFNM}]ubbconfig���뿪ʼ" "$BOLD" "$NORM"
        
        tuxubbnm=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "ubbconfig" | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}'`
        tmloadcf -y "${HOME}$tuxubbnm"
        ls -lrt "${HOME}/etc/tuxconfig"
        
        PrtMsg "[${ARTFNM}]ubbconfig�������" "$BOLD" "$NORM"
    fi
}

ProcHtChkPro(){
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ��������Ƿ����
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep -v "artfhuitui.sh" | awk -F '/' '{split($0,arr,"/")} {printf("%s\n",arr[NF])}' \
        | while read line|| [[ -n ${line} ]];
    do
        proflg=`ps -fu "$LOGNAME" | grep -vE "grep|ldbc.cfg" | grep -w "$line" | wc -l`
        while [ $proflg -gt 0 ];do
            PrtMsg "$line����δֹͣ,����ִ��ͣ$line����..." "$NORM" "$NORM"
        
            #��ȡproc.list�ļ���ͣ����
            procline=`cat ${HOME}/etc/proc.list | grep -v "^#" | grep -v "^$" | grep -w "$line"`
            if [ "x$procline" != "x" ];then
                Name=`echo ${procline}|awk -F'[\]:\[]' '{print $1}'`
                Star=`echo ${procline}|awk -F'[\]:\[]' '{print $2}'`
                Shut=`echo ${procline}|awk -F'[\]:\[]' '{print $3}'`
                Turn=`echo ${procline}|awk -F'[\]:\[]' '{print $4}'`
                PrtMsg "$line����δֹͣ����ͨ��${Shut}ͣ����..." "$NORM" "$NORM"
                ${Shut}
            else
                PrtMsg "��proc.list�����õ�ͣ���̲��������ֹ�ֹͣ..." "$BOLD" "$NORM"
            fi
            
            proflg=`ps -fu "$LOGNAME" | grep -v "grep" | grep -w "$line" | wc -l`
            if [ $proflg -eq 0 ];then
                PrtMsg "$line����ֹͣ�ɹ�..." "$NORM" "$NORM"
            fi
            sleep 10
        done
    done
}

ProcHtUpPro(){
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ�����Ƿ���Ҫ������
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep -v "artfhuitui.sh" | awk -F '/' '{split($0,arr,"/")} {printf("%s\n",arr[NF])}' \
        | while read line|| [[ -n ${line} ]];
    do
        #��ȡproc.list�ļ���ͣ����
        procline=`cat ${HOME}/etc/proc.list | grep -v "^#" | grep -v "^$" | grep -w "$line"`
        if [ "x$procline" != "x" ];then
            Name=`echo ${procline}|awk -F'[\]:\[]' '{print $1}'`
            Star=`echo ${procline}|awk -F'[\]:\[]' '{print $2}'`
            Shut=`echo ${procline}|awk -F'[\]:\[]' '{print $3}'`
            Turn=`echo ${procline}|awk -F'[\]:\[]' '{print $4}'`
            
            if [ ${Turn} = "ON" ];then
                PrtMsg "$line����δ��������ͨ��${Star}������..." "$NORM" "$NORM"
                ${Star}
            fi
            proflg=`ps -fu "$LOGNAME" | grep -v "grep" | grep -w "$line" | wc -l`
            if [ $proflg -gt 0 ];then
                PrtMsg "$line���������ɹ�..." "$NORM" "$NORM"
            fi
        else 
            PrtMsg "$line��proc.list���÷�ʽ��������ȷ���Ƿ���Ҫ����..." "$NORM" "$NORM"
        fi
    done
}

ProcHtSqlData(){
    PrtMsg "[${ARTFNM}]�������û��˿�ʼ" "$BOLD" "$NORM"
    
    #�������ļ�����ARTFDATABAK����Ŀ¼
    export FDIR=${ARTFDATABAK}
    
    #�������û���
    sh ${ARTFSQLDATA}/${ARTFNO}i.sh
    
    PrtMsg "[${ARTFNM}]�������û������" "$BOLD" "$NORM"
}

ProcHtDiffCopy(){
    PrtMsg "[${ARTFNM}]�����ļ����˿�ʼ" "$BOLD" "$NORM"
    
    #������ʱ�����ļ�
    HtDiffCopy=${ARTFTMP}/HtDiffCopy.tm.${PID}
    
    #��ȡ�����ļ�${ARTFDIFFCOPY}/diffcopy.list���ݲ���������
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ -s '${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" ];then cp -p '${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" %s",$0)} {printf(";fi;\n")}' > ${HtDiffCopy}
    
    #ִ�л��˲���
    sh ${HtDiffCopy}
    cat ${HtDiffCopy}
    rm -f ${HtDiffCopy}
    
    PrtMsg "[${ARTFNM}]�����ļ��������" "$BOLD" "$NORM"
}

ProcHtSameCopy(){
    PrtMsg "[${ARTFNM}]��ִ���ļ����˿�ʼ" "$BOLD" "$NORM"
    
    #������ʱ�����ļ�
    HtSameCopy=${ARTFTMP}/HtSameCopy.tm.${PID}
    
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ���������
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep -v "artfhuitui.sh" | awk -F '/' '{split($0,arr,"/")} {printf("if [ -s '${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" ];then cp -p '${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" %s;chmod 750 %s",$0,$0)} {printf(";fi;\n")}' > ${HtSameCopy}
    
    #�ж��Ƿ���Ҫͣtuxedo����
    ProcHtChkTux
    
    #�ж��Ƿ���Ҫͣ��Ӧ����
    ProcHtChkPro
    
    #ִ�л��˲���
    sh ${HtSameCopy}
    cat ${HtSameCopy}
    rm -f ${HtSameCopy}
    
    #�������˽���
    #ProcHtUpPro
    
    #�ж�samecopy.list���Ƿ����artfhuitui.sh����
    if [ `cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep "artfhuitui.sh" | wc -l` -ne 0 ];then
        PrtMsg "[artfhuanban.sh]����������ɺ�ͨ���ֹ�ִ��[cp -p ${ARTFDATABAK}/sbin/artfhuitui.sh ~/sbin/artfhuitui.sh]���ˣ����������" "$BOLD" "$NORM"
        if [ "$REMOTE" != "true" ];then
            read
        fi
    fi
    
    PrtMsg "[${ARTFNM}]��ִ���ļ��������" "$BOLD" "$NORM"
}

ProcHtDbOperate(){
    PrtMsg "[${ARTFNM}]���ݿ�������˿�ʼ: " "$BOLD" "$NORM"
    
    DBNAME=$1
    filesql=$2
    
    cd ${ARTFDATABAK}
    if [ `cat $filesql | grep -v "^--" | grep -v "^$" | wc -l` -ne 0 ];then
        cat $filesql | grep -v "^--" | grep -v "^$"
        OperateDB "$DBNAME" "$filesql" "Ret"
        if [ ${Ret} -ne "0" ]
        then
            echo "[$filesql]���ݿ����ʧ��"
        fi
    fi
    cd -
    
    PrtMsg "[${ARTFNM}]���ݿ�������˽���: " "$BOLD" "$NORM"
}

ProcHtSqlData
ProcHtDiffCopy
ProcHtSameCopy
ProcHtDbOperate "$RUNDBNAME" "${ARTFDBOPERATE}/rundbhuitui.sql"
ProcHtDbOperate "$CFGDBNAME" "${ARTFDBOPERATE}/cfgdbhuitui.sql"

PrtMsg "\n[${ARTFNM}]���˽���...\n" "$BOLD" "$NORM"
