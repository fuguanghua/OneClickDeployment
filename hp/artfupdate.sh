#!/bin/sh
##############################################################
#  Create for : artfupdate.sh                                #
#  Create by  : weiqs                                        #
#  Create on  : 2016-08-01                                   #
#  Create at  : Bank of ShangHai                             #
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
ARTFOLD=${PWDDIR}/old

if [ ! -d ${ARTFOLD} ];then
    mkdir -p ${ARTFOLD}
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

#�ж��Ƿ��Ѵ���artfĿ¼
if [ ! -d ${ARTFNM} ];then
    if [ -s ${ARTFNM}.tar ];then
        PrtMsg "[${ARTFNM}]��ѹ�����[${ARTFNM}.tar]" "$NORM" "$NORM"
        tar xvf ${ARTFNM}.tar
        #��ԭ�汾����
        mv ${ARTFNM}.tar ${ARTFOLD}/${ARTFNM}_old_`date +%Y%m%d%H%M%S`.tar
    else
        PrtMsg "${ARTFDIR}.tar������" "$NORM" "$NORM"
        exit 0
    fi
else
    if [ -s ${ARTFNM}.tar ];then
        PrtMsg "[${ARTFNM}]Ŀ¼�Ѵ��ڣ��Ƿ���Ҫ���½�ѹ${ARTFNM}.tar [y/n]?" "$BOLD" "$NORM"
        read anser?
        case $anser in
        Y|y)
            PrtMsg "���������[$anser],���½�ѹ${ARTFNM}.tar..." "$NORM" "$NORM"
            PrtMsg "[${ARTFNM}]��ѹ�����[${ARTFNM}.tar]" "$NORM" "$NORM"
            tar xvf ${ARTFNM}.tar
            #��ԭ�汾����
            mv ${ARTFNM}.tar ${ARTFOLD}/${ARTFNM}_old_`date +%Y%m%d%H%M%S`.tar
            ;;
        *)
            PrtMsg "���������[$anser],����ѹ${ARTFNM}.tar..." "$NORM" "$NORM"
            ;;
        esac
    fi
fi

#��ӡִ����Ϣ
PrtMsg "[${ARTFNM}]���뻷�����²���...\n" "$BOLD" "$NORM"


ProcUpSameCopy(){
    PrtMsg "[${ARTFNM}]��ִ���ļ����¿�ʼ" "$BOLD" "$NORM"
    
    #������ʱ�����ļ�
    UpSameCopy=${HOME}/tmp/UpSameCopy.tm
    
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ���������
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | grep -E "\/lib\/|\/bin\/" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")} {printf("if [ -s %s ];then cp -p %s ",$0,$0)} {printf("'${ARTFSAMECOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";fi;\n")}' > ${UpSameCopy}
    
    #ִ�б��ݲ���
    sh ${UpSameCopy}
    cat ${UpSameCopy}
    rm -f ${UpSameCopy}
    
    PrtMsg "[${ARTFNM}]��ִ���ļ��������" "$BOLD" "$NORM"
}

ProcPkTar(){
    PrtMsg "[${ARTFNM}]tar����ʼ" "$BOLD" "$NORM"
    
    #��${PWDDIR}Ŀ¼�ڴ��
    tar cvf ${ARTFNM}.tar ${ARTFNM}
    
    PrtMsg "[${ARTFNM}]tar�����" "$BOLD" "$NORM"
}

ProcUpSameCopy
ProcPkTar
