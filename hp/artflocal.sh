#!/bin/sh
##############################################################
#  Create for : artflocal.sh                                 #
#  Create by  : weiqs                                        #
#  Create on  : 2017-01-01                                   #
#  Create at  : Bank of ShangHai                             #
#  System of  : HP-UNIX                                      #
##############################################################

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

#����ѡ����Ÿ�ʽ
PS3="��� => " ; export PS3

#��ȡ��ǰĿ¼�Ļ����
PrtMsg "��ѡ����Ҫ�����Ļ����" "$BOLD" "$NORM"
select tarnm in `ls -F $PWD | grep -E "^artf([0-9]{3,8}).tar$|^artfall.tar$"`
do
    PrtMsg "�����Ϊ��$tarnm" "$NORM" "$NORM"
    break
done
if [ "x$tarnm" = "x" ];then
    PrtMsg "û�л����" "$NORM" "$NORM"
    exit 0
fi

PrtMsg "��ѡ����Ҫ�����Ĳ���" "$BOLD" "$NORM"
select operate in "����&����" "����" "����" "����" "����&����(����ͣ)" "����(����ͣ)" "����(����ͣ)" "����(����ͣ)"
do
    PrtMsg "ѡ��Ĳ���Ϊ��$operate" "$NORM" "$NORM"
    break
done
if [ "x$operate" = "x" ];then
    PrtMsg "�������" "$NORM" "$NORM"
    exit 0
fi
if [ `echo $operate | grep "����ͣ" | wc -l` -ne 0 ];then
    PrtMsg "��������������(��������÷ֺ�;�ֿ���bosloadҲ�ڴ�����)" "$BOLD" "$NORM"
    read inputstart?
    PrtMsg "������ֹͣ����(��������÷ֺ�;�ֿ�)" "$BOLD" "$NORM"
    read inputstop?
fi

#����ֺ�У��
if [ "x$inputstart" != "x" ];then
    inputstart=`echo $inputstart|sed 's/$/;/'|sed 's/;;/;/'`
fi
if [ "x$inputstop" != "x" ];then
    inputstop=`echo $inputstop|sed 's/$/;/'|sed 's/;;/;/'`
fi
OPSTR1=""
OPSTR2=""
#���������
ARTFNO=`echo $tarnm | sed 's/.tar//g'`
if [ `echo $operate | grep "����" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} sh ./beifen.sh;"
    OPSTR2="${OPSTR2} artfbeifen.sh ${ARTFNO} 2>&1 | tee -a ${ARTFNO}.beifen.log;"
fi
if [ `echo $operate | grep "����" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} $inputstop sh ./huanban.sh; $inputstart"
    OPSTR2="${OPSTR2} $inputstop artfhuanban.sh ${ARTFNO} 2>&1 | tee -a ${ARTFNO}.huanban.log; $inputstart"
fi
if [ `echo $operate | grep "����" | wc -l` -ne 0 ];then
    OPSTR1="${OPSTR1} $inputstop sh ./huitui.sh; $inputstart"
    OPSTR2="${OPSTR2} $inputstop artfhuitui.sh ${ARTFNO} 2>&1 | tee -a ${ARTFNO}.huitui.log; $inputstart"
fi
#echo OPSTR1:${OPSTR1}
#echo OPSTR2:${OPSTR2}

PrtMsg "\n��ȷ���Ƿ���б����������(y/n)?" "$BOLD" "$NORM"
read input?
case $input in
Y|y)
    break
    ;;
*)
    PrtMsg "��ֹ���л���" "$NORM" "$NORM"
    exit 0
    ;;
esac

artflocal="$HOME/tmp/artflocal.sh"
>$artflocal
#�ж��Ƿ�һ�������
if [ "$tarnm" = "artfall.tar" ];then
    #һ�������
    tar xvf artfall.tar
    echo "${OPSTR1}" >> $artflocal
else
    #���������
    echo "${OPSTR2}" >> $artflocal
fi
sh $artflocal
rm -f $artflocal
 