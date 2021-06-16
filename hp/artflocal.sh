#!/bin/sh
##############################################################
#  Create for : artflocal.sh                                 #
#  Create by  : weiqs                                        #
#  Create on  : 2017-01-01                                   #
#  Create at  : Bank of ShangHai                             #
#  System of  : HP-UNIX                                      #
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

#定义选择序号格式
PS3="序号 => " ; export PS3

#获取当前目录的换版包
PrtMsg "请选择你要操作的换版包" "$BOLD" "$NORM"
select tarnm in `ls -F $PWD | grep -E "^artf([0-9]{3,8}).tar$|^artfall.tar$"`
do
    PrtMsg "换版包为：$tarnm" "$NORM" "$NORM"
    break
done
if [ "x$tarnm" = "x" ];then
    PrtMsg "没有换版包" "$NORM" "$NORM"
    exit 0
fi

PrtMsg "请选择你要操作的步骤" "$BOLD" "$NORM"
select operate in "备份&换版" "备份" "换版" "回退" "备份&换版(含启停)" "备份(含启停)" "换版(含启停)" "回退(含启停)"
do
    PrtMsg "选择的操作为：$operate" "$NORM" "$NORM"
    break
done
if [ "x$operate" = "x" ];then
    PrtMsg "步骤错误" "$NORM" "$NORM"
    exit 0
fi
if [ `echo $operate | grep "含启停" | wc -l` -ne 0 ];then
    PrtMsg "请输入启动命令(多个命令用分号;分开，bosload也在此输入)" "$BOLD" "$NORM"
    read inputstart?
    PrtMsg "请输入停止命令(多个命令用分号;分开)" "$BOLD" "$NORM"
    read inputstop?
fi

#命令分号校验
if [ "x$inputstart" != "x" ];then
    inputstart=`echo $inputstart|sed 's/$/;/'|sed 's/;;/;/'`
fi
if [ "x$inputstop" != "x" ];then
    inputstop=`echo $inputstop|sed 's/$/;/'|sed 's/;;/;/'`
fi
OPSTR1=""
OPSTR2=""
#组操作命令
ARTFNO=`echo $tarnm | sed 's/.tar//g'`
if [ `echo $operate | grep "备份" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} sh ./beifen.sh;"
    OPSTR2="${OPSTR2} artfbeifen.sh ${ARTFNO} 2>&1 | tee -a ${ARTFNO}.beifen.log;"
fi
if [ `echo $operate | grep "换版" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} $inputstop sh ./huanban.sh; $inputstart"
    OPSTR2="${OPSTR2} $inputstop artfhuanban.sh ${ARTFNO} 2>&1 | tee -a ${ARTFNO}.huanban.log; $inputstart"
fi
if [ `echo $operate | grep "回退" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} $inputstop sh ./huitui.sh; $inputstart"
    OPSTR2="${OPSTR2} $inputstop artfhuitui.sh ${ARTFNO} 2>&1 | tee -a ${ARTFNO}.huitui.log; $inputstart"
fi
#echo OPSTR1:${OPSTR1}
#echo OPSTR2:${OPSTR2}

PrtMsg "\n请确认是否进行本机换版操作(y/n)?" "$BOLD" "$NORM"
read input?
case $input in
Y|y)
    break
    ;;
*)
    PrtMsg "终止进行换版" "$NORM" "$NORM"
    exit 0
    ;;
esac

artflocal="$HOME/tmp/artflocal.sh"
>$artflocal
#判断是否一键换版包
if [ "$tarnm" = "artfall.tar" ];then
    #一键换版包
    tar xvf artfall.tar
    echo "${OPSTR1}" >> $artflocal
else
    #单个任务包
    echo "${OPSTR2}" >> $artflocal
fi
sh $artflocal
rm -f $artflocal
 