#!/bin/sh
##############################################################
#  Create for : artfcheck.sh                                 #
#  Create on  : 2016-08-01                                   #
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

ProcChkDbl(){
    filename=$1
    srcpath=$2
    PWDDIR=`pwd`
    
    cat $filename | grep -v "^#" | grep -v "^$" | grep -v "artf00000" | awk -F ':' '{print ("|"$2)}' | sort | uniq -c | awk -F '|' '{if($1>1) print($2)}' | \
        while read chkline || [[ -n ${chkline} ]];
    do
        PrtMsg "[$srcpath]Ŀ¼[$chkline]�����ظ���¼������" "$HIGH" "$NORM"
        #echo "${chkline}"
        cat $filename | grep -v "^#" | grep -v "^$" | grep -v "artf00000" | grep "${chkline}" | awk '{printf($0"\n")}'
    done
    
    #�����diffcopy����ظ��ļ�����Ҫ�������
    if [ $srcpath = "diffcopy" ];then
        cat $filename | grep -v "^#" | grep -v "^$" | awk -F ':' '{print ("|"$2)}' | sort | uniq -c | awk -F '|' '{if($1>1) print($2)}' | while read chkdiffline || [[ -n ${chkdiffline} ]];
        do
            diffdir=`echo ${chkdiffline} | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF-1;i++)printf("/%s",arr[i])}'`
            prognm=`echo ${chkdiffline} | awk -F '/' '{split($0,arr,"/")} {printf("%s",arr[NF])}'`
            #echo "$diffdir $prognm"
            
            #�����ظ�����ƥ��artf��
            >nosigle
            echo "artf00000" > packall.list.tm
            cat packall.list >> packall.list.tm
            cat $filename | grep -v "^#" | grep -v "^$" | grep "${chkdiffline}" | awk -F ':' '{print($1)}' | while read atrfnm
            do
                #����artf�Ż�ȡ�ظ����ݵ�ָ��˳��
                cat packall.list.tm | grep -v "^#" | grep -v "^$" | grep -n $atrfnm >> nosigle
            done
            rm packall.list.tm

            #��ȡָ������������
            PrtMsg "�ظ�����[${chkdiffline}]��packall.list�еİ汾˳��Ϊ:" "$BOLD" "$NORM"
            cat nosigle | grep -v "^#" | grep -v "^$" | sort | awk -F ':' '{print($2)}'
            cat nosigle | grep -v "^#" | grep -v "^$" | sort | awk -F ':' '{print($2)}' | tr '\n' '|' | awk -F '|' '{split($0,arr,"|")} {for(i=1;i<=NF-2;i++)printf("%s|%s\n",arr[i],arr[i+1])}' | while read commline
            do
                prevartfno=`echo "$commline" | awk -F '|' '{print $1}'`
                nextartfno=`echo "$commline" | awk -F '|' '{print $2}'`
                #echo "$prevartfno $nextartfno"
                prevnm=./$prevartfno/diffcopy$diffdir/$prognm
                nextnm=./$nextartfno/diffcopy$diffdir/$prognm
                
                #���µ��ļ���׺��Ϊ�����бȶ�
                for flgnextnm in `ls $nextnm*`
                do
                    flgprevnm=`echo $flgnextnm | sed 's/'$nextartfno'/'$prevartfno'/'`
                    PrtMsg "�°汾[$flgnextnm]��ԭ�汾[$flgprevnm]�Ա�:" "$BOLD" "$NORM"
                    diff $flgprevnm $flgnextnm | grep -E "^<|^>" | awk '{if($0~/^< /) {gsub("^< ", "");} else if($0~/^> /) {gsub("^> ", "");printf($0"\n")} }' > commrstadd
                    diff $flgprevnm $flgnextnm | grep -E "^<|^>" | awk '{if($0~/^< /) {gsub("^< ", "");printf($0"\n")} else if($0~/^> /) {gsub("^> ", "");} }' > commrstfew
                    diff commrstadd commrstfew | grep -E "^<|^>" | awk '{if($0~/^< /) {gsub("^< ", "��������:");} else if($0~/^> /) {gsub("^> ", "ȱ������:");} {printf("\033[7m"$0"\033[0m\n")} }'
                    rm -f commrstadd commrstfew
                done
            done

            rm nosigle
        done
    fi
}

ProcCheck(){
    #artf���
    ARTFNM=$1
    
    #��ȡartf��
    ARTFNO=`echo ${ARTFNM} | sed 's/\/$//' | awk -F '/' '{print $NF}' | sed 's/artf//g'`
    #echo ${ARTFNO}
    
    #�������Ŀ¼
    PWDDIR=`pwd`
    ARTFDIR=${PWDDIR}/${ARTFNM}
    ARTFDATABAK=${ARTFDIR}/databak
    ARTFDIFFCOPY=${ARTFDIR}/diffcopy
    ARTFSAMECOPY=${ARTFDIR}/samecopy
    ARTFSQLDATA=${ARTFDIR}/sqldata
    ARTFDBOPERATE=${ARTFDIR}/dboperate
    
    PrtMsg "$i:[${ARTFNM}]�����鿪ʼ" "$BOLD" "$NORM"
    
    #���diffcopy.listĿ¼�Ƿ񴴽���δ�������Զ�����Ŀ¼
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("if [ ! -d '${ARTFDIFFCOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(" ];then mkdir -p '${ARTFDIFFCOPY}'/")} {for(i=2;i<=NF-1;i++)printf("%s/",arr[i])} {printf(";fi; \n")} ' > ${HOME}/tmp/CkDiffCopy.tm
    sh ${HOME}/tmp/CkDiffCopy.tm
    rm ${HOME}/tmp/CkDiffCopy.tm
    
    #���diffcopy.list�������Ƿ��Ѵ��
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} \
        {printf("ls '${ARTFDIFFCOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(".sit.*\n")} \
        {printf("ls '${ARTFDIFFCOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(".uat.*\n")} \
        {printf("ls '${ARTFDIFFCOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(".prod.*\n")}' \
        | while read diffline || [[ -n ${diffline} ]];
    do
        #�ж��ļ��Ƿ����
        $diffline 2>&1 | grep "not found" | grep -v "artf00000"
        
        #�ж��Ƿ��������IP��ַ
        filenm=`echo $diffline | sed 's/ls //`
        #echo $filenm
        if [ -s $filenm ];then
            cntnm=`cat $filenm | grep -v "^#" | grep -v "^$" | grep -E "10\.240\.([0-9]{1,3})\.([0-9]{1,3})|11\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})" | wc -l`
            ifprodflg=`echo $filenm | grep -E '.prod.' | wc -l` #���������ļ�����Ƿ��������IP
            if [ $cntnm -ne 0 ] && [ $ifprodflg -ne 0 ];then
                PrtMsg "[���ڲ���]IP[$filenm]: " "$HIGH" "$NORM"
                cat $filenm | grep -v "^#" | grep -v "^$" | grep -E "10\.240\.([0-9]{1,3})\.([0-9]{1,3})|11\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})" | awk '{printf("\033[5m"$0"\033[0m\n")}'
            fi
        fi
    done
    
    #���samecopy.list�������Ƿ��Ѵ��
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} \
        {printf("ls '${ARTFSAMECOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}' \
        | while read sameline || [[ -n ${sameline} ]];
    do
        $sameline 2>&1 | grep "not found" | grep -v "artf00000"
    done
    
    #���${ARTFNO}i.sh�������Ƿ��Ѵ��
    cat ${ARTFSQLDATA}/${ARTFNO}i.sh | grep -v "^#" | grep -v "^$" | awk -F ' ' '{split($0,arr," ")} 
        {if(arr[2]=="-c" || arr[2]=="c") printf("ls '${ARTFSQLDATA}'/%s\n",arr[NF])}
        {if(arr[2]=="-h" || arr[2]=="h") printf("ls '${ARTFSQLDATA}'/%s\n",arr[NF])}
        {if(arr[2]=="-n" || arr[2]=="n") printf("ls '${ARTFSQLDATA}'/%s\n","Node")}
        {if(arr[2]=="-m" || arr[2]=="m") printf("ls '${ARTFSQLDATA}'/%s\n","Macr")}
        {if(arr[2]=="-d" || arr[2]=="d") printf("ls '${ARTFSQLDATA}'/%s\n","Dict")}
        {if(arr[2]=="-t" || arr[2]=="t") printf("ls '${ARTFSQLDATA}'/%s\n","Func")}
        {if(arr[2]=="-a" || arr[2]=="a") printf("ls '${ARTFSQLDATA}'/%s\n","Func")}
        {if(arr[2]=="-e" || arr[2]=="e") printf("ls '${ARTFSQLDATA}'/%s\n","Code")}
        {if(arr[2]=="-g" || arr[2]=="g") printf("ls '${ARTFSQLDATA}'/%s\n","Category")}
        {if(arr[2]=="-l" || arr[2]=="l") printf("ls '${ARTFSQLDATA}'/%s\n","Libary")} ' \
        | while read sqlline || [[ -n ${sqlline} ]];
    do
        $sqlline 2>&1 | grep "not found" | grep -v "artf00000"
        
        #�ж��Ƿ��������IP��ַ
        filenm=`echo $sqlline | sed 's/ls //`
        #echo $filenm
        if [ -d $filenm ];then
            cntnm=`cat $filenm/* | grep -v "^#" | grep -v "^$" | grep -E "10\.240\.([0-9]{1,3})\.([0-9]{1,3})|11\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})" | wc -l`
            if [ $cntnm -ne 0 ];then
                PrtMsg "[���ڲ���IP][$filenm]: " "$HIGH" "$NORM"
                find $filenm -name "*"  | xargs grep -v "^#" | grep -v "^$" | grep -E "10\.240\.([0-9]{1,3})\.([0-9]{1,3})|11\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})" | awk -F ':' '{printf($1" : ")}{printf("\033[5m"$2"\033[0m\n")}'
            fi
        fi
    done
    
    #���${ARTFNO}i.sh������ȷ������ǷǴ�͸���ף���Ҫ�ж��е������������
    cat ${ARTFSQLDATA}/${ARTFNO}i.sh | grep -v "^#" | grep -v "^$" | awk -F ' ' '{split($0,arr," ")}
        {if(arr[2]=="-c" || arr[2]=="c") printf("'${ARTFSQLDATA}'/%s/svcroute.TXT\n",arr[NF])}' |
        while read sqlline || [[ -n ${sqlline} ]];
    do
        if [ -s $sqlline ];then
            cat $sqlline | awk -F '|' '{split($0,arr,"|")} {if((arr[3]=="1")&&(arr[7]=="0")) printf("")}'
        fi
    done
    
    
    #�г���Ӧ�ӱ�����б�����
    echo "[${ARTFNM}]${ARTFDIFFCOPY}/diffcopy.list" >> checkout.list
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$">> checkout.list
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$">> diffcopy.list.tm
    
    echo "\n" >> checkout.list
    echo "[${ARTFNM}]${ARTFSAMECOPY}/samecopy.list" >> checkout.list
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$">> checkout.list
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$">> samecopy.list.tm
    
    echo "\n" >> checkout.list
    echo "[${ARTFNM}]${ARTFSQLDATA}/${ARTFNO}i.sh" >> checkout.list
    cat ${ARTFSQLDATA}/${ARTFNO}i.sh | grep -v "^#" | grep -v "^$">> checkout.list
    inum=`cat ${ARTFSQLDATA}/${ARTFNO}i.sh | grep -v "^#" | grep -v "^$" | wc -l`
    echo "��[$inum]����¼����\n" >> checkout.list
    cat ${ARTFSQLDATA}/${ARTFNO}i.sh | grep -v "^#" | grep -v "^$">> 00000i.sh.tm
    
    echo "[${ARTFNM}]${ARTFSQLDATA}/${ARTFNO}o.sh" >> checkout.list
    cat ${ARTFSQLDATA}/${ARTFNO}o.sh | grep -v "^#" | grep -v "^$">> checkout.list
    onum=`cat ${ARTFSQLDATA}/${ARTFNO}o.sh | grep -v "^#" | grep -v "^$" | wc -l`
    echo "��[$onum]����¼����\n" >> checkout.list
    cat ${ARTFSQLDATA}/${ARTFNO}o.sh | grep -v "^#" | grep -v "^$">> 00000o.sh.tm
    
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" >> checkout.list
    
    #�������Ƿ����ظ���Ϣ
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | sed "s/^/${ARTFNM}:/g">>diffcopy.chk
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | sed "s/^/${ARTFNM}:/g">>samecopy.chk
    cat ${ARTFSQLDATA}/${ARTFNO}i.sh | grep -v "^#" | grep -v "^$" | sed "s/^/${ARTFNM}:/g">>sqldata.chk
    cat ${ARTFSQLDATA}/${ARTFNO}o.sh | grep -v "^#" | grep -v "^$" | sed "s/^/${ARTFNM}:/g">>sqldata.chk

    if [ ${allnum} -eq $i ] && [ $allnum -ne 1 ];then
        #artf00000Ŀ¼Ϊ�������߰汾
        if [ ! -d "artf00000" ];then
            artfinit.sh artf00000
        fi
        cat diffcopy.list.tm | sort -u > ${PWDDIR}/artf00000/diffcopy/diffcopy.list
        cat samecopy.list.tm | sort -u > ${PWDDIR}/artf00000/samecopy/samecopy.list
        cat 00000i.sh.tm | sort -u > ${PWDDIR}/artf00000/sqldata/00000i.sh
        cat 00000o.sh.tm | sort -u > ${PWDDIR}/artf00000/sqldata/00000o.sh
    fi
    
    PrtMsg "$i:[${ARTFNM}]���������" "$BOLD" "$NORM"
}

i=1
rm -f checkout.list

#�������Ϊartf��ţ���ָ��artf��ż��
isatrf=`echo $1 | grep -E 'artf([0-9]{3,8})$' | wc -l`
if [ $isatrf -eq 1 ];then
    #�ж��Ƿ��Ѵ���artfĿ¼
    if [ ! -d $1 ];then
        tar xvf $1.tar
    fi
    if [ ! -d $1 ];then
        echo "$1Ŀ¼������"
        exit 0
    fi
    allnum=1
    ProcCheck "$1"
else  

    #�����artfxxxxx.tar��δ��ѹ�����Ƚ�ѹtar��
    ls -F | grep -E 'artf([0-9]{3,8}).tar$' | sed 's/.tar//g' | while read TarNm
    do
        if [ ! -d $TarNm ];then
            PrtMsg "${TarNm}.tarδ��ѹ" "$NORM" "$NORM"
            tar xvf ${TarNm}.tar
        fi
    done
    if [ -s packall.list ];then
        ls -F | grep '/$' | sed 's/\/$//' | grep -v "artf00000" | grep -E 'artf([0-9]{3,8})$' | sort  > packlist.new
        cat packall.list | sort > packlist.old
        diff packlist.old packlist.new | grep -E "^<|^>" | awk '{if($0~/^< /) {gsub("^< ", "�뵱ǰĿ¼�Ա�packall.list����:");} else if($0~/^> /) {gsub("^> ", "�뵱ǰĿ¼�Ա�packall.listȱ��:");} printf($0"\n")}' > packlist.rst
        rm packlist.new packlist.old
        if [ -s packlist.rst ];then
            cat packlist.rst | awk '{print("\033[5m"$0"\033[0m")}'
            PrtMsg "��ȷ����ʾ����,��ȷ���Ƿ��ֹ��޸�packall.list,���������ַ�����" "$NORM" "$NORM"
            rm packlist.rst
            read inputlist
        else
            rm -f packlist.rst
        fi
    fi
    
    if [ ! -s packall.list ];then
        PrtMsg "�����ڻ����б�packall.list���Ƿ�ȡ��ǰĿ¼��artf������y/n?" "$BOLD" "$NORM"
        read anser?
        case $anser in
        Y|y)
            PrtMsg "���������[$anser],��ʼ����packall.list..." "$NORM" "$NORM"
            ls -F | grep '/$' | sed 's/\/$//' | grep -v "artf00000" | grep -E 'artf([0-9]{3,8})$' > packall.list
            if [ -s packall.list ];then
                PrtMsg "�����ɵ�packall.list���£���ȷ���Ƿ���Ҫ�ֹ��޸ĸ������˳��..." "$BOLD" "$NORM"
                cat packall.list
                PrtMsg "packall.list�����ɣ�������artfcheck.sh��ɼ��..." "$NORM" "$NORM"
                exit 0
            else
                PrtMsg "��ǰĿ¼������artf�������" "$NORM" "$NORM"
                rm -rf artf00000 checkout.list packall.list
                exit 0
            fi
            ;;
        *)
            PrtMsg "���������[$anser],�˳�" "$NORM" "$NORM"
            rm -rf artf00000 checkout.list packall.list
            exit 0
            ;;
        esac
    else
        cat packall.list > packall.list.ll
        allnum=`cat packall.list.ll | wc -l`
        echo "artf00000" >> packall.list.ll
        cat packall.list.ll | grep -E 'artf([0-9]{3,8})$' | while read DirNm
        do
            ProcCheck "$DirNm"
            i=` expr $i + 1`
        done
        rm packall.list.ll
    fi
fi

#PrtMsg "�����ظ�����" "$BOLD" "$NORM"
ProcChkDbl "diffcopy.chk" "diffcopy"
ProcChkDbl "samecopy.chk" "samecopy"
ProcChkDbl "sqldata.chk" "sqldata"

rm -f diffcopy.list.tm
rm -f samecopy.list.tm
rm -f 00000i.sh.tm
rm -f 00000o.sh.tm

rm -f diffcopy.chk
rm -f samecopy.chk
rm -f sqldata.chk

    