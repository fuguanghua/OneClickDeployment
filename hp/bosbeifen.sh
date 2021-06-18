##############################################################
#  Create for : bosbeifen.sh                                 #
#  Create on  : 2018-04-01                                   #
#  System of  : RedHat                                       #
##############################################################

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

    echo "${head}${mesg}${tail}"
}

#生成列表
if [ ! -s packall.list ];then

    ls *.tar | grep -v "artf00000" | grep -E 'artf([0-9]{3,8})([0-9a-z_]{0,9}).tar$' | sed 's/.tar$//g' > packall.list

fi

if [ -s packall.list ];then

    PrtMsg "请确认备份工件任务列表，是否继续?[y/n]" "$BOLD" "$NORM"
    cat packall.list
    read input
    case $input in
    Y|y)
        ;;
    *)
        exit
        ;;
    esac    
fi

mkdir -p log
#根据任务列表处理
cat packall.list | while read line
do

    artfbeifen.sh ${line} 2>&1 | tee -a ${PWD}/log/beifen.${line}.log 

done

#检查日志
grep -E "fail|error|失败" ${PWD}/log/beifen.*.log

