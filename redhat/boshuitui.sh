##############################################################
#  Create for : boshuitui.sh                                 #
#  Create on  : 2018-04-01                                   #
#  System of  : RedHat                                       #
##############################################################
ARTFFLG='^artf([0-9]{3,8})([0-9a-z_.]{0,9})$|^BH_([A-Za-z0-9_.]{3,30})$'

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

    echo -e "${head}${mesg}${tail}"
}

#匹配包名
case "${LOGNAME}" in
esbapp)
    TAG="(_mng.tar|_imon.tar|_flow.tar|_adp.tar)"
    ;;
esbmng)
    TAG="(_public.tar|_app.tar|_imon.tar|_flow.tar)"
    ;;
esbimon)
    TAG="(_public.tar|_app.tar|_mng.tar|_flow.tar|_adp.tar)"
    ;;
esbflow)
    TAG="(_public.tar|_app.tar|_mng.tar|_imon.tar|_adp.tar)"
    ;;
*)
    exit
    ;;
esac

#定义选择序号格式
PS3="序号 => " ; export PS3

#判断是否包含换版包
artfnum=`ls -F $PWD | grep ".tar" | grep -E "${ARTFFLG}" | grep -Ev "${TAG}" | sed 's/.tar$//g' | wc -l`
if [ ${artfnum} -eq 0 ];then
    PrtMsg "没有任务包" "$NORM" "$NORM"
    exit 0
fi

if [ "$REMOTE" != "true" ];then
PrtMsg "\n请选择你要操作的换版包(multi:多选 all:全部)" "$BOLD" "$NORM"
select opt in `ls -F $PWD | grep ".tar" | grep -E "${ARTFFLG}" | grep -Ev "${TAG}" | sed 's/.tar$//g'` multi all
do
    #echo ${artflist}
    if [ "${opt}" =  "all" ];then
        artflist=${opt}
        echo ${artflist}
        break
    elif [ "${opt}" =  "multi" ] && [ "${MULTI}" != "true" ];then
        export MULTI="true"
        PrtMsg "请选多个换版包，确认后选multi选项退出" "$NORM" "$NORM"
    elif [ "${opt}" =  "multi" ] && [ "${MULTI}" = "true" ];then
        break
    else
        if [ "${MULTI}" = "true" ];then
            if [ `echo "${artflist}" | grep "${opt}" | wc -l` -eq 0 ];then
                artflist="${artflist} ${opt}"
                echo ${artflist}
            else
                PrtMsg "${opt}重复" "$NORM" "$NORM"
                continue
            fi
        else
            artflist=${opt}
            echo ${artflist}
            break
        fi
    fi
done
if [ "x${artflist}" = "x" ];then
    PrtMsg "没有换版包" "$NORM" "$NORM"
    exit 0
fi
PrtMsg "你选择的换版包为:${artflist},请确认是否继续?[y/n]" "$HIGH" "$NORM"
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

else

    artflist=all

fi

mkdir -p log
#根据任务列表处理

if [ "${artflist}" = "all" ];then
    artflist=`ls -F $PWD | grep ".tar" | grep -E "${ARTFFLG}" | grep -Ev "${TAG}" | sed 's/.tar$//g'`
fi

for line in ${artflist}
do
    echo "[${line}-start]`date`" | tee -a ${PWD}/log/${line}.huitui.log
    artfhuitui.sh ${line} 2>&1 | tee -a ${PWD}/log/${line}.huitui.log 
    echo "[${line}-end]`date`" | tee -a ${PWD}/log/${line}.huitui.log
done

#检查日志
if [ -s "${PWD}/log/artf*.huitui.log" ];then
    grep -E -i "fail|error|失败" ${PWD}/log/artf*.huitui.log
fi


