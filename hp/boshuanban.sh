##############################################################
#  Create for : boshuanban.sh                                #
#  Create by  : weiqs                                        #
#  Create on  : 2018-04-01                                   #
#  Create at  : Bank of ShangHai                             #
#  System of  : RedHat                                       #
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

#�����б�
if [ ! -s packall.list ];then

    ls *.tar | grep -v "artf00000" | grep -E 'artf([0-9]{3,8})([0-9a-z_]{0,9}).tar$' | sed 's/.tar$//g' > packall.list

fi

if [ -s packall.list ];then

    PrtMsg "��ȷ�ϱ��ݹ��������б��Ƿ����?[y/n]" "$BOLD" "$NORM"
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
#���������б���
cat packall.list | while read line
do

    artfhuanban.sh ${line} 2>&1 | tee -a ${PWD}/log/huanban.${line}.log 

done

#�����־
grep -E "fail|error|ʧ��" ${PWD}/log/huanban.*.log


