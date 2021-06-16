##############################################################
#  Create for : artfinit.sh                                  #
#  Create by  : weiqs                                        #
#  Create on  : 2016-08-01                                   #
#  Create at  : Bank of ShangHai                             #
#  System of  : RedHat                                       #
##############################################################

ARTFFLG='^artf([0-9]{3,8})([0-9a-z_.]{0,9})$|^BH_([A-Za-z0-9_.]{3,30})$'

[ $# -ne 1 ] && {
    echo "请输入版本编号,如: artf12345 或者 BH_ESB_20.05.01"
    exit 0
}

isatrf=`echo $1 | grep -E "${ARTFFLG}" | wc -l`
if [ $isatrf -eq 0 ];then
    echo "你输入版本编号非法"
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
    echo '#逐行列出有区别文件全路径文件名,如: ~/SmartESB/configs/in_conf/conf/config-mysql.properties' > ${ARTFDIFFCOPY}/diffcopy.list
fi
if [ ! -f ${ARTFSAMECOPY}/samecopy.list ];then
    touch ${ARTFSAMECOPY}/samecopy.list
    echo '#逐行列出无区别文件全路径文件名,如: ~/SmartESB/bin/startSmart.sh' > ${ARTFSAMECOPY}/samecopy.list
fi
if [ ! -f ${ARTFSQLDATA}/${ARTFNO}i.sh ];then
    touch ${ARTFSQLDATA}/${ARTFNO}i.sh
    echo '#逐行列出需要导入的交易配置信息,如: bosmng -c -i EBIP 162000401' > ${ARTFSQLDATA}/${ARTFNO}i.sh
fi
if [ ! -f ${ARTFSQLDATA}/${ARTFNO}o.sh ];then
    touch ${ARTFSQLDATA}/${ARTFNO}o.sh
    echo '#逐行列出需要导出的交易配置信息,如: bosmng -c -o EBIP 162000401' > ${ARTFSQLDATA}/${ARTFNO}o.sh
fi

if [ ! -f ${ARTFDBOPERATE}/imondbbeifen.sql ];then
    touch ${ARTFDBOPERATE}/imondbbeifen.sql
    echo '--逐行列出监控库(esbimon)需要备份步骤' > ${ARTFDBOPERATE}/imondbbeifen.sql
    echo '--1)备份sql数据格式(备份文件在databak目录下)：@备份文件名|表名|WHERE条件(可略),如 @xt_tykj.bak.sql|xt_tykj|where XT_TYKJ_KJMC="xzqh"; ' >> ${ARTFDBOPERATE}/imondbbeifen.sql
fi
if [ ! -f ${ARTFDBOPERATE}/imondbhuanban.sql ];then
    touch ${ARTFDBOPERATE}/imondbhuanban.sql
    echo '--逐行列出监控库(esbimon)需要操作步骤' > ${ARTFDBOPERATE}/imondbhuanban.sql
    echo '--1)执行sql语句格式(直接按书写sql语句执行换版)：如 update xt_tykj set XT_TYKJ_KJMC="xzqh"; ' >> ${ARTFDBOPERATE}/imondbhuanban.sql
    echo '--2)执行sql文件格式(执行sql文件请放dboperate目录下)：@文件名,如 @xt_tykj.sql' >> ${ARTFDBOPERATE}/imondbhuanban.sql
fi
if [ ! -f ${ARTFDBOPERATE}/imondbhuitui.sql ];then
    touch ${ARTFDBOPERATE}/imondbhuitui.sql
    echo '--逐行列出监控库(esbimon)需要回退步骤' > ${ARTFDBOPERATE}/imondbhuitui.sql
    echo '--1)执行sql语句格式(直接按书写sql语句执行回退)：如 update xt_tykj set XT_TYKJ_KJMC="xzqh"; ' >> ${ARTFDBOPERATE}/imondbhuitui.sql
    echo '--1)执行sql文件格式(databak目录下备份文件进行回退)：@备份文件名,如 @xt_tykj.bak.sql' >> ${ARTFDBOPERATE}/imondbhuitui.sql
fi
if [ ! -f ${ARTFDBOPERATE}/mngdbbeifen.sql ];then
    touch ${ARTFDBOPERATE}/mngdbbeifen.sql
    echo '--逐行列出管理库(esbmng)需要备份步骤' > ${ARTFDBOPERATE}/mngdbbeifen.sql
    echo '--1)备份sql数据格式(备份文件在databak目录下)：@备份文件名|表名|WHERE条件(可略),如 @xt_tykj.bak.sql|xt_tykj|where XT_TYKJ_KJMC="xzqh"; ' >> ${ARTFDBOPERATE}/mngdbbeifen.sql
fi
if [ ! -f ${ARTFDBOPERATE}/mngdbhuanban.sql ];then
    touch ${ARTFDBOPERATE}/mngdbhuanban.sql
    echo '--逐行列出管理库(esbmng)需要操作步骤' > ${ARTFDBOPERATE}/mngdbhuanban.sql
    echo '--1)执行sql语句格式(直接按书写sql语句执行换版)：如 update xt_tykj set XT_TYKJ_KJMC="xzqh"; ' >> ${ARTFDBOPERATE}/mngdbhuanban.sql
    echo '--2)执行sql文件格式(执行sql文件请放dboperate目录下)：@文件名,如 @xt_tykj.sql' >> ${ARTFDBOPERATE}/mngdbhuanban.sql
fi
if [ ! -f ${ARTFDBOPERATE}/mngdbhuitui.sql ];then
    touch ${ARTFDBOPERATE}/mngdbhuitui.sql
    echo '--逐行列出管理库(esbmng)需要回退步骤' > ${ARTFDBOPERATE}/mngdbhuitui.sql
    echo '--1)执行sql语句格式(直接按书写sql语句执行回退)：如 update xt_tykj set XT_TYKJ_KJMC="xzqh"; ' >> ${ARTFDBOPERATE}/mngdbhuitui.sql
    echo '--2)执行sql文件格式(databak目录下备份文件进行回退)：@备份文件名,如 @xt_tykj.bak.sql' >> ${ARTFDBOPERATE}/mngdbhuitui.sql
fi

if [ ! -f ${ARTFDBOPERATE}/opttoken.json ];then
    touch ${ARTFDBOPERATE}/opttoken.json
    echo '#添加json格式令牌数据#' > ${ARTFDBOPERATE}/opttoken.json
fi
