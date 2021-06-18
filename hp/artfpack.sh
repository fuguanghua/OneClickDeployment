#!/bin/sh
##############################################################
#  Create for : artfpack.sh                                  #
#  Create on  : 2016-08-01                                   #
#  System of  : HP-UNIX                                      #
##############################################################

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
PrtMsg "[${ARTFNM}]�������...\n" "$BOLD" "$NORM"


ProcPkSqlData(){
    PrtMsg "[${ARTFNM}]�������õ�����ʼ" "$BOLD" "$NORM"
    
    #�������ļ�����ARTFSQLDATA����Ŀ¼
    export FDIR=${ARTFSQLDATA}
    
    #�������õ���
    sh ${ARTFSQLDATA}/${ARTFNO}o.sh
    
    PrtMsg "[${ARTFNM}]�������õ������" "$BOLD" "$NORM"
}

ProcPkSameCopy(){
    PrtMsg "[${ARTFNM}]��ִ���ļ������ʼ" "$BOLD" "$NORM"
    
    #������ʱ�����ļ�
    PkSameCopy=${HOME}/tmp/PkSameCopy.tm
    
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ���������
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")}  {printf("cp -p %s ",$0)} {printf("'${ARTFSAMECOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";\n")}' > ${PkSameCopy}
    
    #ִ�д������
    sh ${PkSameCopy}
    #cat ${PkSameCopy}
    rm -f ${PkSameCopy}
    
    PrtMsg "[${ARTFNM}]��ִ���ļ�������" "$BOLD" "$NORM"
}

ProcPkTar(){
    PrtMsg "[${ARTFNM}]tar����ʼ" "$BOLD" "$NORM"
    
    #��${PWDDIR}Ŀ¼�ڴ��
    tar cvf ${ARTFNM}.tar ${ARTFNM}
    
    PrtMsg "[${ARTFNM}]tar�����" "$BOLD" "$NORM"
}

ProcPkSqlData
ProcPkSameCopy
ProcPkTar
