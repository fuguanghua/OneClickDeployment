#!/bin/sh
##############################################################
#  Create for : artfinit.sh                                  #
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

#�ж��Ƿ��Ѵ���artfĿ¼
if [ -d ${ARTFDIR} ];then
    echo "${ARTFDIR}Ŀ¼�Ѵ���"
fi

#����Ŀ¼
mkdir -p ${ARTFDIR}
mkdir -p ${ARTFDATABAK}
mkdir -p ${ARTFDIFFCOPY}
mkdir -p ${ARTFSAMECOPY}
mkdir -p ${ARTFSQLDATA}
mkdir -p ${ARTFDBOPERATE}

#������ʼ�ļ���
if [ ! -f ${ARTFDIFFCOPY}/diffcopy.list ];then
    touch ${ARTFDIFFCOPY}/diffcopy.list
    echo '#�����г��������ļ�ȫ·���ļ���,��: ${HOME}/etc/dmconfig' > ${ARTFDIFFCOPY}/diffcopy.list
fi
if [ ! -f ${ARTFSAMECOPY}/samecopy.list ];then
    touch ${ARTFSAMECOPY}/samecopy.list
    echo '#�����г��������ļ�ȫ·���ļ���,��: ${HOME}/sbin/logs' > ${ARTFSAMECOPY}/samecopy.list
fi
if [ ! -f ${ARTFSQLDATA}/${ARTFNO}i.sh ];then
    touch ${ARTFSQLDATA}/${ARTFNO}i.sh
    echo '#�����г���Ҫ����Ľ���������Ϣ,��: bosmng -c -i 1631' > ${ARTFSQLDATA}/${ARTFNO}i.sh
fi
if [ ! -f ${ARTFSQLDATA}/${ARTFNO}o.sh ];then
    touch ${ARTFSQLDATA}/${ARTFNO}o.sh
    echo '#�����г���Ҫ�����Ľ���������Ϣ,��: bosmng -c -o 1631' > ${ARTFSQLDATA}/${ARTFNO}o.sh
fi

if [ ! -f ${ARTFDBOPERATE}/rundbbeifen.sql ];then
    touch ${ARTFDBOPERATE}/rundbbeifen.sql
    echo '--�����г����п�(bosdb)��Ҫ���ݵ�sql���' > ${ARTFDBOPERATE}/rundbbeifen.sql
fi
if [ ! -f ${ARTFDBOPERATE}/rundbhuanban.sql ];then
    touch ${ARTFDBOPERATE}/rundbhuanban.sql
    echo '--�����г����п�(bosdb)��Ҫ������sql���' > ${ARTFDBOPERATE}/rundbhuanban.sql
fi
if [ ! -f ${ARTFDBOPERATE}/rundbhuitui.sql ];then
    touch ${ARTFDBOPERATE}/rundbhuitui.sql
    echo '--�����г����п�(bosdb)��Ҫ���˵�sql���' > ${ARTFDBOPERATE}/rundbhuitui.sql
fi
if [ ! -f ${ARTFDBOPERATE}/cfgdbbeifen.sql ];then
    touch ${ARTFDBOPERATE}/cfgdbbeifen.sql
    echo '--�����г����ÿ�(boslink)��Ҫ���ݵ�sql���' > ${ARTFDBOPERATE}/cfgdbbeifen.sql
fi
if [ ! -f ${ARTFDBOPERATE}/cfgdbhuanban.sql ];then
    touch ${ARTFDBOPERATE}/cfgdbhuanban.sql
    echo '--�����г����ÿ�(boslink)��Ҫ������sql���' > ${ARTFDBOPERATE}/cfgdbhuanban.sql
fi
if [ ! -f ${ARTFDBOPERATE}/cfgdbhuitui.sql ];then
    touch ${ARTFDBOPERATE}/cfgdbhuitui.sql
    echo '--�����г����ÿ�(boslink)��Ҫ���˵�sql���' > ${ARTFDBOPERATE}/cfgdbhuitui.sql
fi
