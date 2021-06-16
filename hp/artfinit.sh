#!/bin/sh
##############################################################
#  Create for : artfinit.sh                                  #
#  Create by  : weiqs                                        #
#  Create on  : 2016-08-01                                   #
#  Create at  : Bank of ShangHai                             #
#  System of  : HP-UNIX                                      #
##############################################################

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

#判断是否已存在artf目录
if [ -d ${ARTFDIR} ];then
    echo "${ARTFDIR}目录已存在"
fi

#创建目录
mkdir -p ${ARTFDIR}
mkdir -p ${ARTFDATABAK}
mkdir -p ${ARTFDIFFCOPY}
mkdir -p ${ARTFSAMECOPY}
mkdir -p ${ARTFSQLDATA}
mkdir -p ${ARTFDBOPERATE}

#创建初始文件名
if [ ! -f ${ARTFDIFFCOPY}/diffcopy.list ];then
    touch ${ARTFDIFFCOPY}/diffcopy.list
    echo '#逐行列出有区别文件全路径文件名,如: ${HOME}/etc/dmconfig' > ${ARTFDIFFCOPY}/diffcopy.list
fi
if [ ! -f ${ARTFSAMECOPY}/samecopy.list ];then
    touch ${ARTFSAMECOPY}/samecopy.list
    echo '#逐行列出无区别文件全路径文件名,如: ${HOME}/sbin/logs' > ${ARTFSAMECOPY}/samecopy.list
fi
if [ ! -f ${ARTFSQLDATA}/${ARTFNO}i.sh ];then
    touch ${ARTFSQLDATA}/${ARTFNO}i.sh
    echo '#逐行列出需要导入的交易配置信息,如: bosmng -c -i 1631' > ${ARTFSQLDATA}/${ARTFNO}i.sh
fi
if [ ! -f ${ARTFSQLDATA}/${ARTFNO}o.sh ];then
    touch ${ARTFSQLDATA}/${ARTFNO}o.sh
    echo '#逐行列出需要导出的交易配置信息,如: bosmng -c -o 1631' > ${ARTFSQLDATA}/${ARTFNO}o.sh
fi

if [ ! -f ${ARTFDBOPERATE}/rundbbeifen.sql ];then
    touch ${ARTFDBOPERATE}/rundbbeifen.sql
    echo '--逐行列出运行库(bosdb)需要备份的sql语句' > ${ARTFDBOPERATE}/rundbbeifen.sql
fi
if [ ! -f ${ARTFDBOPERATE}/rundbhuanban.sql ];then
    touch ${ARTFDBOPERATE}/rundbhuanban.sql
    echo '--逐行列出运行库(bosdb)需要操作的sql语句' > ${ARTFDBOPERATE}/rundbhuanban.sql
fi
if [ ! -f ${ARTFDBOPERATE}/rundbhuitui.sql ];then
    touch ${ARTFDBOPERATE}/rundbhuitui.sql
    echo '--逐行列出运行库(bosdb)需要回退的sql语句' > ${ARTFDBOPERATE}/rundbhuitui.sql
fi
if [ ! -f ${ARTFDBOPERATE}/cfgdbbeifen.sql ];then
    touch ${ARTFDBOPERATE}/cfgdbbeifen.sql
    echo '--逐行列出配置库(boslink)需要备份的sql语句' > ${ARTFDBOPERATE}/cfgdbbeifen.sql
fi
if [ ! -f ${ARTFDBOPERATE}/cfgdbhuanban.sql ];then
    touch ${ARTFDBOPERATE}/cfgdbhuanban.sql
    echo '--逐行列出配置库(boslink)需要操作的sql语句' > ${ARTFDBOPERATE}/cfgdbhuanban.sql
fi
if [ ! -f ${ARTFDBOPERATE}/cfgdbhuitui.sql ];then
    touch ${ARTFDBOPERATE}/cfgdbhuitui.sql
    echo '--逐行列出配置库(boslink)需要回退的sql语句' > ${ARTFDBOPERATE}/cfgdbhuitui.sql
fi
