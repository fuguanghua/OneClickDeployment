##############################################################
#  Create for : artfpack.sh                                  #
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

#PID
PID=$$

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
if [ ! -d ${ARTFDIR} ];then
    echo "${ARTFDIR}目录不存在"
    exit 0
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

    echo  -e "${head}${mesg}${tail}"
}

#打印执行信息
PrtMsg "[${ARTFNM}]打包操作...\n" "$BOLD" "$NORM"

#匹配HOSTNMID
GetNMID()
{
    FILEPATH=$1
    FLAG=$2

    if [ "$LOGNAME" != "esbmng" ];then
        return
    fi

    if [ -d ${FILEPATH} ];then
        find ${FILEPATH} -name "protocolbind.*.sql.*" | grep "${FLAG}" 2>/dev/null
        if [ $? -ne 0 ];then
            find ${FILEPATH} -name protocolbind.*.sql
            PrtMsg "不包含HOSTNMID以${FLAG}结尾的标识，请确认" "$HIGH" "$NORM"
            read
        fi
    fi

}

#对sqldata导入导出标识进行校验
CheckSqlFlag()
{
    errinflag=`grep -vE "^#|^$" ${ARTFSQLDATA}/${ARTFNO}i.sh | awk '{if($3 != "-i") print $0;}'`
    if [ "x${errinflag}" != "x" ];then
        PrtMsg "${errinflag}" "$NORM" "$NORM"
        PrtMsg "[${ARTFSQLDATA}/${ARTFNO}i.sh]出现非-i标识，请确认" "$BOLD" "$NORM"
    fi

    errouflag=`grep -vE "^#|^$" ${ARTFSQLDATA}/${ARTFNO}o.sh | awk '{if($3 != "-o") print $0;}'`
    if [ "x${errouflag}" != "x" ];then
        PrtMsg "${errouflag}" "$NORM" "$NORM"
        PrtMsg "[${ARTFSQLDATA}/${ARTFNO}o.sh]出现非-o标识，请确认" "$BOLD" "$NORM"
    fi

    errchflag=`grep -vE "^#|^$" ${ARTFSQLDATA}/${ARTFNO}i.sh ${ARTFSQLDATA}/${ARTFNO}o.sh | awk '{if($2 != "-c" && $2 != "-h") print $0;}'`
    if [ "x${errchflag}" != "x" ];then
        PrtMsg "${errchflag}" "$NORM" "$NORM"
        PrtMsg "[${ARTFSQLDATA}/${ARTFNO}o.sh或${ARTFSQLDATA}/${ARTFNO}i.sh]出现非-c|-h标识，请确认" "$BOLD" "$NORM"
    fi

    if [ "x${errouflag}" != "x" ] || [ "x${errinflag}" != "x" ] || [ "x${errchflag}" != "x" ];then
        [ -f ${1} ] && rm ${1}
        exit
    fi
}

ProcPkSqlData(){
    PrtMsg "[${ARTFNM}]交易配置导出开始" "$BOLD" "$NORM"

    #导出临时日志用于判断导出空的结果
    OUTPUTLOG=${ARTFSQLDATA}/.out.log.${PID}

    #检查sqldata导入导出标识
    CheckSqlFlag ${OUTPUTLOG}
    
    #将配置文件导向ARTFSQLDATA换版目录
    export FDIR=${ARTFSQLDATA}
    
    #交易配置导出
    export ARTFPACKFLAG=${ARTFNO}.pk
    sh ${ARTFSQLDATA}/${ARTFNO}o.sh | tee ${OUTPUTLOG} 

    #判断导出结果是否为空
    if [ `grep -c "data is null" ${OUTPUTLOG}` -ne 0 ];then
        grep "data is null" ${OUTPUTLOG}
        PrtMsg "请检查以上空记录" "$BOLD" "$NORM"
        read
    fi
    [ -f ${OUTPUTLOG} ] && rm -f ${OUTPUTLOG}
    
    PrtMsg "[${ARTFNM}]交易配置导出完成" "$BOLD" "$NORM"
}

ProcPkSameCopy(){
    PrtMsg "[${ARTFNM}]可执行文件打包开始" "$BOLD" "$NORM"
    
    #定义临时操作文件
    PkSameCopy=${HOME}/tmp/PkSameCopy.tm
    
    #读取配置文件${ARTFSAMECOPY}/samecopy.list内容并组操作语句
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFSAMECOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi;")}  {printf("cp -p %s ",$0)} {printf("'${ARTFSAMECOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";\n")}' > ${PkSameCopy}
    
    #执行打包操作
    sh ${PkSameCopy}
    #cat ${PkSameCopy}
    rm -f ${PkSameCopy}
    
    PrtMsg "[${ARTFNM}]可执行文件打包完成" "$BOLD" "$NORM"
}

ProcDatabak(){
    PrtMsg "[${ARTFNM}]清理目录[${ARTFDATABAK}]" "$BOLD" "$NORM"
    if [[ ${ARTFDATABAK} =~ "databak" ]];then
        rm -rf ${ARTFDATABAK}/*
    fi
}

ProcPkTar(){
    PrtMsg "[${ARTFNM}]tar包开始" "$BOLD" "$NORM"
    
    #打包前判断protocolbind表语句是否带HOSTNMID
    FILEPATH=${ARTFSQLDATA}/sql/Host
    GetNMID ${FILEPATH} "PROD"
    GetNMID ${FILEPATH} "UAT"
    GetNMID ${FILEPATH} "SIT"

    #在${PWDDIR}目录内打包
    tar cvf ${ARTFNM}.tar ${ARTFNM}
    
    PrtMsg "[${ARTFNM}]tar包完成" "$BOLD" "$NORM"
}

#对列表文件$进行转义
sed -i 's/.\$/\\$/g;s/[\][\]*\$/\\$/g' ${ARTFSAMECOPY}/samecopy.list
sed -i 's/.\$/\\$/g;s/[\][\]*\$/\\$/g' ${ARTFDIFFCOPY}/diffcopy.list

ProcPkSqlData
ProcPkSameCopy
ProcDatabak
ProcPkTar
