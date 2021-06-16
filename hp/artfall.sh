#!/bin/sh
##############################################################
#  Create for : artfall.sh                                   #
#  Create by  : weiqs                                        #
#  Create on  : 2016-08-01                                   #
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

#�ڵ�ǰ������artf�����
if [ ! -s packall.list ];then
    PrtMsg "����ͨ��artfcheck.sh��ɰ汾���" "$NORM" "$NORM"
    exit 0
fi

if [ -s packall.list ];then
    ls -F | grep '/$' | sed 's/\/$//' | grep -v "artf00000" | grep -E 'artf([0-9]{3,8})$' | sort  > packlist.new
    cat packall.list | sort > packlist.old
    diff packlist.old packlist.new | grep -E "^<|^>" | awk '{if($0~/^< /) {gsub("^< ", "�뵱ǰĿ¼�Ա�packall.list����:");} else if($0~/^> /) {gsub("^> ", "�뵱ǰĿ¼�Ա�packall.listȱ��:");} printf($0"\n")}' > packlist.rst
    if [ -s packlist.rst ];then
        cat packlist.rst | awk '{print("\033[5m"$0"\033[0m")}'
        PrtMsg "��ȷ����ʾ����,��ȷ���Ƿ��ֹ��޸�packall.list,���������ַ�����" "$NORM" "$NORM"
        read inputlist
    fi
    rm packlist.new packlist.old packlist.rst
fi


cat packall.list | while read DirNm
do
    echo "artfbeifen.sh $DirNm 2>&1 | tee -a beifen.log" >> beifen.sh
    echo "artfhuanban.sh $DirNm 2>&1 | tee -a huanban.log" >> huanban.sh
    echo "artfhuitui.sh $DirNm 2>&1 | tee -a huitui.log" >> huitui.sh
    if [ ! -s $DirNm.tar ];then
        artfpack.sh $DirNm
    fi
done

rm -f artfall.tar
#ƴ��������ַ���
artflist=""
for list in `cat packall.list`
do
    artflist="$artflist ${list}.tar"
done
#echo $artflist
tar cvf artfall.tar $artflist beifen.sh huanban.sh huitui.sh packall.list
tar tvf artfall.tar
rm -f beifen.sh huanban.sh huitui.sh
