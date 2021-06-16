##############################################################
#  Create for : artfall.sh                                   #
#  Create by  : weiqs                                        #
#  Create on  : 2016-08-01                                   #
#  Create at  : Bank of ShangHai                             #
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

#在当前批处理artf换版包
if [ ! -s packall.list ];then
    PrtMsg "请先通过artfcheck.sh完成版本检查" "$NORM" "$NORM"
    exit 0
fi

if [ -s packall.list ];then
    ls -F | grep '/$' | sed 's/\/$//' | grep -v "artf00000" | grep -E "${ARTFFLG}" | sort  > packlist.new
    cat packall.list | sort > packlist.old
    diff packlist.old packlist.new | grep -E "^<|^>" | awk '{if($0~/^< /) {gsub("^< ", "与当前目录对比packall.list多了:");} else if($0~/^> /) {gsub("^> ", "与当前目录对比packall.list缺少:");} printf($0"\n")}' > packlist.rst
    if [ -s packlist.rst ];then
        cat packlist.rst | awk '{print("\033[5m"$0"\033[0m")}'
        PrtMsg "请确认提示内容,并确认是否手工修改packall.list,输入任意字符继续" "$NORM" "$NORM"
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
#拼接任务包字符串
artflist=""
for list in `cat packall.list`
do
    artflist="$artflist ${list}.tar"
done
#echo $artflist
tar cvf artfall.tar $artflist beifen.sh huanban.sh huitui.sh packall.list
tar tvf artfall.tar
rm -f beifen.sh huanban.sh huitui.sh

