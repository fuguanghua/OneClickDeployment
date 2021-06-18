#!/bin/sh
##############################################################
#  Create for : artfbeifen.sh                                #
#  Create on  : 2016-08-01                                   #
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

#�ж��Ƿ��Ѵ���artfĿ¼
if [ -d ${ARTFDIR} ];then
    mv ${ARTFDIR} ${ARTFDIR}.bak.`date +'%m%d%H%M%S'`
fi
if [ -s ${ARTFNM}.tar ];then
    PrtMsg "[${ARTFNM}]��ѹ�����[${ARTFNM}.tar]" "$NORM" "$NORM"
    tar xvf ${ARTFNM}.tar 2>&1 1>/dev/null
else
    PrtMsg "${ARTFDIR}.tar������" "$NORM" "$NORM"
    exit 0
fi

#��ӡִ����Ϣ
PrtMsg "\n[${ARTFNM}]���ݿ�ʼ...\n" "$BOLD" "$NORM"

OperateDB()
{
    DBNM=$1
    File=$2
    Ret=$3
    dbaccess ${DBNM} < ${File} 2>&1
    eval ${Ret}=$?
}

ProcBfSqlData(){
    PrtMsg "[${ARTFNM}]�������ñ��ݿ�ʼ" "$BOLD" "$NORM"
    
    DbmBakDir=$HOME/bak/${CFGDBNAME}/`date +%Y%m%d`
    if [ -d ${DbmBakDir} ];then
        PrtMsg "[${ARTFNM}]�������ݿⱸ���Ѵ���:${DbmBakDir}" "$BOLD" "$NORM"
    else
        PrtMsg "[${ARTFNM}]���ݿⱸ��..." "$BOLD" "$NORM"
        DBM -b
    fi
    
    #�������ļ�����ARTFDATABAK����Ŀ¼
    export FDIR=${ARTFDATABAK}
    
    #�������ñ���
    sh ${ARTFSQLDATA}/${ARTFNO}o.sh
    
    PrtMsg "[${ARTFNM}]�������ñ������" "$BOLD" "$NORM"
}

ProcBfDiffCopy(){
    PrtMsg "[${ARTFNM}]�����ļ����ݿ�ʼ" "$BOLD" "$NORM"
    
    #������ʱ�����ļ�
    BfDiffCopy=${ARTFTMP}/BfDiffCopy.tm.${PID}
    
    #��ȡ�����ļ�${ARTFDIFFCOPY}/diffcopy.list���ݲ���������
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFDATABAK}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFDATABAK}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")}  {printf("if [ -s %s ];then cp -p %s ",$0,$0)} {printf("'${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";fi;\n")}' > ${BfDiffCopy}
    
    #ִ�б��ݲ���
    sh ${BfDiffCopy}
    cat ${BfDiffCopy}
    rm -f ${BfDiffCopy}
    
    PrtMsg "[${ARTFNM}]�����ļ��������" "$BOLD" "$NORM"
}

ProcBfSameCopy(){
    PrtMsg "[${ARTFNM}]��ִ���ļ����ݿ�ʼ" "$BOLD" "$NORM"
    
    #������ʱ�����ļ�
    BfSameCopy=${ARTFTMP}/BfSameCopy.tm.${PID}
    
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ���������
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFDATABAK}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFDATABAK}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")}  {printf("if [ -s %s ];then cp -p %s ",$0,$0)} {printf("'${ARTFDATABAK}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";fi;\n")}' > ${BfSameCopy}
    
    #ִ�б��ݲ���
    sh ${BfSameCopy}
    cat ${BfSameCopy}
    rm -f ${BfSameCopy}
    
    PrtMsg "[${ARTFNM}]��ִ���ļ��������" "$BOLD" "$NORM"
}

ProcBfDbOperate(){
    PrtMsg "[${ARTFNM}]���ݿ�������ݿ�ʼ: " "$BOLD" "$NORM"
    
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
    
    PrtMsg "[${ARTFNM}]���ݿ�������ݽ���: " "$BOLD" "$NORM"
}

ProcBfList(){
    PrtMsg "[${ARTFNM}]����Ŀ¼���ļ�����: " "$BOLD" "$NORM"
    #�г����еı����ļ�
    ls -R ${ARTFDATABAK}
}

ProcBfSqlData
ProcBfDiffCopy
ProcBfSameCopy
ProcBfDbOperate "$RUNDBNAME" "${ARTFDBOPERATE}/rundbbeifen.sql"
ProcBfDbOperate "$CFGDBNAME" "${ARTFDBOPERATE}/cfgdbbeifen.sql"
ProcBfList

PrtMsg "\n[${ARTFNM}]���ݽ���...\n" "$BOLD" "$NORM"
