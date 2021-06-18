#!/bin/sh
##############################################################
#  Create for : artfhuanban.sh                               #
#  Create on  : 2016-08-01                                   #
#  System of  : HP-UNIX                                      #
##############################################################
PID=$$

[ $# -ne 1 ] && {
    echo "������artf�汾���,��: artf12345"
    exit 0
}

isatrf=`echo $1 | grep -E 'artf([0-9]{3,8})$' | wc -l`
if [ $isatrf -eq 0 ];then
    echo "������artf��ŷǷ�"
    exit 0
fi

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
ARTFTMP="$HOME/tmp/artf"
mkdir -p ${ARTFTMP}
DIFFRST=${ARTFTMP}/diffrst.rst.${PID}

#����30����ǰ�����ļ�
CleanTmpTOU(){
    DELDIR=$1
    perl -e 'my $dir="'"$DELDIR"'";opendir DH,$dir or die "cannot chdir to $dir : $!";for my $file(readdir DH){my $fpath=$dir."/".$file;if(((time()-(stat($fpath))[10])>1800)&&($fpath =~ /artf/)){unlink $fpath;}}closedir DH;'
}
CleanTmpTOU "${ARTFTMP}"

#����Ŀ¼δ��ѹ�����ѹ
if [ ! -d ${ARTFDIR} ];then
    echo "${ARTFDIR}Ŀ¼������"
    tar xvf ${ARTFNM}.tar 2>&1 1>/dev/null
fi
#����ظ����棬�����½�ѹ
if [ -s ${PWDDIR}/break.txt ];then
    tarflg=`cat ${PWDDIR}/break.txt | grep "${ARTFNO}" | wc -l`
else
    tarflg=0
fi
if [ -d ${ARTFDIR} ] && [ ${tarflg} -ne 0 ];then
    echo "${ARTFDIR}���½�ѹ"
    #mv ${ARTFDIR} ${ARTFDIR}.bak.`date +'%m%d%H%M%S'`
    tar xvf ${ARTFNM}.tar 2>&1 1>/dev/null
fi

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

#��ӡִ����Ϣ
PrtMsg "\n[${ARTFNM}]���濪ʼ...\n" "$BOLD" "$NORM"

OperateDB()
{
    DBNM=$1
    File=$2
    Ret=$3
    dbaccess ${DBNM} < ${File} 2>&1
    eval ${Ret}=$?
}

DiffChk(){
    #��ȡ�����ļ�${ARTFDIFFCOPY}/diffcopy.list����ԭ�ļ����бȶ�
    while true
    do
        >${DIFFRST}
        cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("'${HOME}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" '${ARTFDIFFCOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(".'${HOSTNMID}'")}  {printf("\n")}' | while read diffline;
        do
            oldname=`echo $diffline | awk '{print($1)}'`
            newname=`echo $diffline | awk '{print($2)}'`

            if [ -s $oldname ];then
                diff $diffline | grep -E "^<|^>" | awk '{if($0~/^> /) {gsub("^> ", "'$newname'��������:");} else if($0~/^< /) {gsub("^< ", "'$newname'ȱ������:");} printf($0"\n")}' >> ${DIFFRST}
            fi
        done
        if [ -s ${DIFFRST} ];then
            cat ${DIFFRST} | awk -F ':' '{if($1~/ȱ������/) printf("\033[7m"$0"\033[0m\n");else printf($0"\n");}'
            if [ `cat ${DIFFRST} | grep "ȱ������" | wc -l` -gt 0 ] && [ "$REMOTE" != "true" ];then
                PrtMsg "[${ARTFNM}]ȱ����������" "$BOLD" "$NORM"
                PrtMsg "*************************" "$BOLD" "$NORM"
                PrtMsg " y)���Լ��             *" "$BOLD" "$NORM"
                PrtMsg " c)���¼��             *" "$BOLD" "$NORM"
                PrtMsg " *)��������ֹ�����˳�   *" "$BOLD" "$NORM"
                PrtMsg "*************************" "$BOLD" "$NORM"
                read anser?
                case $anser in
                Y|y)
                    PrtMsg "���������[$anser],������ʾ,��������..." "$NORM" "$NORM"
                    break
                    ;;
                C|c)
                    PrtMsg "���������[$anser],���¼��..." "$NORM" "$NORM"
                    continue
                    ;;
                *)
                    PrtMsg "���������[$anser],��ͣ����..." "$NORM" "$NORM"
                    exit 0
                    ;;
                esac
            else
                break
            fi
        else
            break
        fi
    done
    rm ${DIFFRST}
}

ProcHbChkTux(){
    #ͨ��diffcopy.listƥ��ubbconfig��dmconfig�ж��Ƿ���Ҫֹͣtuxedo����
    tuxdmflg=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "dmconfig" | wc -l`
    tuxubbflg=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "ubbconfig" | wc -l`

    if [ $tuxdmflg -gt 0 ];then
        #�ж�BBL�Ƿ�������
        tuxpro=`ps -u "$LOGNAME" | grep -v "grep" | grep -w "BBL" | wc -l`
        while [ $tuxpro -gt 0 ];do
            PrtMsg "tuxedoδֹͣ,��ȫͣӦ��,10������¼��..." "$NORM" "$NORM"
            tuxpro=`ps -u "$LOGNAME" | grep -v "grep" | grep -w "BBL" | wc -l`
            sleep 10
        done
        
        PrtMsg "[${ARTFNM}]dmconfig���뿪ʼ" "$BOLD" "$NORM"
        
        tuxdmnm=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" |  grep "dmconfig" | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}'`
        dmloadcf -y "${HOME}$tuxdmnm"
        ls -lrt "${HOME}/etc/bdmconfig"
        
        PrtMsg "[${ARTFNM}]dmconfig�������" "$BOLD" "$NORM"
    fi

    if [ $tuxubbflg -gt 0 ];then
        #�ж�BBL�Ƿ�������
        tuxpro=`ps -u "$LOGNAME" | grep -v "grep" | grep -w "BBL" | wc -l`
        while [ $tuxpro -gt 0 ];do
            PrtMsg "tuxedoδֹͣ,��ȫͣӦ��,10������¼��..." "$NORM" "$NORM"
            tuxpro=`ps -u "$LOGNAME" | grep -v "grep" | grep -w "BBL" | wc -l`
            sleep 10
        done
        
        PrtMsg "[${ARTFNM}]ubbconfig���뿪ʼ" "$BOLD" "$NORM"
        
        tuxubbnm=`cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | grep "ubbconfig" | awk -F '/' '{split($0,arr,"/")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf("\n")}'`
        tmloadcf -y "${HOME}$tuxubbnm"
        ls -lrt "${HOME}/etc/tuxconfig"
        
        PrtMsg "[${ARTFNM}]ubbconfig�������" "$BOLD" "$NORM"
    fi
}

ProcHbChkPro(){
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ��������Ƿ����
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | grep -v "artfhuanban.sh" | awk -F '/' '{split($0,arr,"/")} {printf("%s\n",arr[NF])}' \
        | while read line|| [[ -n ${line} ]];
    do
        proflg=`ps -fu "$LOGNAME" | grep -vE "grep|ldbc.cfg" | grep -w "$line" | wc -l`
        while [ $proflg -gt 0 ];do
            PrtMsg "$line����δֹͣ,����ִ��ͣ$line����..." "$NORM" "$NORM"
            
            #��ȡproc.list�ļ���ͣ����
            procline=`cat ${HOME}/etc/proc.list | grep -v "^#" | grep -v "^$" | grep -w "$line"`
            if [ "x$procline" != "x" ];then
                Name=`echo ${procline}|awk -F'[\]:\[]' '{print $1}'`
                Star=`echo ${procline}|awk -F'[\]:\[]' '{print $2}'`
                Shut=`echo ${procline}|awk -F'[\]:\[]' '{print $3}'`
                Turn=`echo ${procline}|awk -F'[\]:\[]' '{print $4}'`
                PrtMsg "����ͨ��${Shut}ͣ$line����..." "$NORM" "$NORM"
                ${Shut}
            else
                PrtMsg "��proc.list�����õ�ͣ���̲��������ֹ�ֹͣ..." "$NORM" "$NORM"
            fi
            
            proflg=`ps -fu "$LOGNAME" | grep -v "grep" | grep -w "$line" | wc -l`
            if [ $proflg -eq 0 ];then
                PrtMsg "$line������ֹͣ..." "$NORM" "$NORM"
                continue
            else
                PrtMsg "$line����δֹͣ��10���������..." "$NORM" "$NORM"
            fi
            sleep 10
        done
    done
}

ProcHbUpPro(){
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ�����Ƿ���Ҫ������
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | grep -v "artfhuanban.sh" | awk -F '/' '{split($0,arr,"/")} {printf("%s\n",arr[NF])}' \
        | while read line|| [[ -n ${line} ]];
    do

        #��ȡproc.list�ļ���ͣ����
        procline=`cat ${HOME}/etc/proc.list | grep -v "^#" | grep -v "^$" | grep -w "$line"`
        if [ "x$procline" != "x" ];then
            Name=`echo ${procline}|awk -F'[\]:\[]' '{print $1}'`
            Star=`echo ${procline}|awk -F'[\]:\[]' '{print $2}'`
            Shut=`echo ${procline}|awk -F'[\]:\[]' '{print $3}'`
            Turn=`echo ${procline}|awk -F'[\]:\[]' '{print $4}'`
            
            if [ ${Turn} = "ON" ];then
                PrtMsg "$line����δ��������ͨ��${Star}������..." "$NORM" "$NORM"
                ${Star}
            fi
            proflg=`ps -fu "$LOGNAME" | grep -v "grep" | grep -w "$line" | wc -l`
            if [ $proflg -gt 0 ];then
                PrtMsg "$line���������ɹ�..." "$NORM" "$NORM"
            fi
        else 
            PrtMsg "$line��proc.list���÷�ʽ��������ȷ���Ƿ���Ҫ����..." "$BOLD" "$NORM"
        fi
    done
}

ProcBreakHb(){
    #�ϵ㻻��
    
    #��һ������Ϊ��Ŀ¼���ڶ�������Ϊִ���ļ���
    SubDir=$1
    FileNm=$2
    #echo "SubDir:$SubDir FileNm:$FileNm"
    
    HbBreak=${ARTFTMP}/HbBreak.tm.${PID}
    if [ ! -s ${PWDDIR}/break.txt ];then
        touch ${PWDDIR}/break.txt
    fi

    >${HbBreak}
    cat $FileNm | grep -v "^#" | grep -v "^$" | while read lineshell
    do
        if [ `cat ${PWDDIR}/break.txt | grep "${ARTFNM}|${SubDir}|succ|$lineshell" | wc -l` -eq 0 ];then
            echo "$lineshell" | tee -a ${HbBreak}
            echo "if [ \$? -eq 0 ];then" >> ${HbBreak}
            echo "    echo \"${ARTFNM}|${SubDir}|succ|$lineshell\" >> ${PWDDIR}/break.txt" >> ${HbBreak}
            echo "else" >> ${HbBreak}
            echo "    echo \"[$lineshell]\033[5mִ��ʧ��\033[0m\" " >> ${HbBreak}
            echo "fi" >> ${HbBreak}
        else
            PrtMsg "[$lineshell]����ɣ�����ִ��..." "$NORM" "$NORM"
        fi
    done
    sh ${HbBreak}
    rm -f ${HbBreak}
}

ProcHbSqlData(){
    PrtMsg "[${ARTFNM}]�������û��濪ʼ" "$BOLD" "$NORM"
    
    #�������ļ�����ARTFSQLDATA����Ŀ¼
    export FDIR=${ARTFSQLDATA}
    
    #�жϵ�������Ŀ¼�Ƿ�����ݲ�ͬ��������
    if [ "x$HOSTNMID" != "x" ];then
        for Sqldiff in `ls -F ${ARTFSQLDATA} | grep "/$" | sed 's/\///g' | grep "${HOSTNMID}"`
        do
            #echo "Sqldiff:${ARTFSQLDATA}/$Sqldiff"
            Sqldir=`echo $Sqldiff | sed "s/.${HOSTNMID}//g"`
            #echo "Sqldir:$Sqldir Sqldiff:$Sqldiff"
            if [ "x$Sqldir" != "x" ];then
                rm -rf ${ARTFSQLDATA}/$Sqldir
                cp -R ${ARTFSQLDATA}/$Sqldiff ${ARTFSQLDATA}/$Sqldir
            fi
        done
    fi
    
    #�������û���
    ProcBreakHb "sqldata" "${ARTFSQLDATA}/${ARTFNO}i.sh"
    
    PrtMsg "[${ARTFNM}]�������û������" "$BOLD" "$NORM"
}

ProcHbDiffCopy(){
    PrtMsg "[${ARTFNM}]�����ļ����濪ʼ" "$BOLD" "$NORM"
    
    #��������ļ��Ƿ���©���߰汾����
    DiffChk
    
    #������ʱ�����ļ�
    HbDiffCopy=${ARTFTMP}/HbDiffCopy.tm.${PID}
    
    #��ȡ�����ļ�${ARTFDIFFCOPY}/diffcopy.list���ݲ���������
    cat ${ARTFDIFFCOPY}/diffcopy.list | grep -v "^#" | grep -v "^$" | awk -F '/' '{split($0,arr,"/")} {printf("cp -p '${ARTFDIFFCOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(".'${HOSTNMID}' '${HOME}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";\n")}' > ${HbDiffCopy}
    
    #ִ�л������
    ProcBreakHb "diffcopy" "${HbDiffCopy}"
    rm -f ${HbDiffCopy}
    
    PrtMsg "[${ARTFNM}]�����ļ��������" "$BOLD" "$NORM"
}

ProcHbSameCopy(){
    PrtMsg "[${ARTFNM}]��ִ���ļ����濪ʼ" "$BOLD" "$NORM"
    
    #������ʱ�����ļ�
    HbSameCopy=${ARTFTMP}/HbSameCopy.tm.${PID}
    
    #��ȡ�����ļ�${ARTFSAMECOPY}/samecopy.list���ݲ���������
    cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$" | grep -v "artfhuanban.sh" | awk -F '/' '{split($0,arr,"/")} {printf("cp -p '${ARTFSAMECOPY}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(" '${HOME}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";chmod 750 '${HOME}'")} {for(i=2;i<=NF;i++)printf("/%s",arr[i])} {printf(";\n")}' > ${HbSameCopy}
    
    #�ж��Ƿ���Ҫͣtuxedo����
    ProcHbChkTux
    
    #�ж��Ƿ���Ҫͣ��Ӧ����
    ProcHbChkPro
    
    #ִ�л������
    ProcBreakHb "samecopy" "${HbSameCopy}"
    rm -f ${HbSameCopy}
    
    #�����������
    #ProcHbUpPro
    
    #�ж�samecopy.list���Ƿ����artfhuanban.sh����
    if [ `cat ${ARTFSAMECOPY}/samecopy.list | grep -v "^#" | grep -v "^$"  | grep "artfhuanban.sh" | wc -l` -ne 0 ];then
        HbSbinCopy=${ARTFTMP}/HbSbinCopy.tm
        >${HbSbinCopy}
        echo "while [ true ]" >>${HbSbinCopy}
        echo "do" >>${HbSbinCopy}
        echo "    if [ "'`ps -fu $LOGNAME | grep -v grep | grep artfhuanban.sh | wc -l`'" -eq 0 ];then" >>${HbSbinCopy}
        echo "        cp -p ${ARTFSAMECOPY}/sbin/artfhuanban.sh ~/sbin/artfhuanban.sh" >>${HbSbinCopy}
        echo "        chmod 750 ~/sbin/artfhuanban.sh" >>${HbSbinCopy}
        echo "        break" >>${HbSbinCopy}
        echo "    else" >>${HbSbinCopy}
        echo "        sleep 1" >>${HbSbinCopy}
        echo "    fi" >>${HbSbinCopy}
        echo "done" >>${HbSbinCopy}
        sh ${HbSbinCopy} &
    fi
    
    PrtMsg "[${ARTFNM}]��ִ���ļ��������" "$BOLD" "$NORM"
}

ProcHbDbOperate(){
    PrtMsg "[${ARTFNM}]���ݿ�������濪ʼ: " "$BOLD" "$NORM"
    
    DBNAME=$1
    filesql=$2
    
    cd ${ARTFDBOPERATE}
    if [ `cat ${PWDDIR}/break.txt | grep "${ARTFNM}|dboperate|succ|$filesql" | wc -l` -eq 0 ];then
        if [ `cat $filesql | grep -v "^--" | grep -v "^$" | wc -l` -ne 0 ];then
            cat $filesql | grep -v "^--" | grep -v "^$"
            OperateDB "$DBNAME" "$filesql" "Ret"
            if [ ${Ret} -ne "0" ]
            then
                echo "[$filesql]���ݿ����ʧ��"
            else
                echo "${ARTFNM}|dboperate|succ|$filesql" >> ${PWDDIR}/break.txt
            fi
        fi
    else
        PrtMsg "[$filesql]����ɣ�����ִ��..." "$NORM" "$NORM"
    fi
    cd -
    
    PrtMsg "[${ARTFNM}]���ݿ�����������: " "$BOLD" "$NORM"
}

ProcBreakDel(){
    #�ж��Ƿ���Ҫɾ���ϵ��ļ�
    if [ ! -s ${PWDDIR}/break.txt ];then
        touch ${PWDDIR}/break.txt
    fi
    bknum=`cat ${PWDDIR}/break.txt | grep "^$ARTFNM|" | wc -l`
    if [ $bknum -ne 0 ];then
        if [ "$REMOTE" = "true" ];then
            cat ${PWDDIR}/break.txt | grep -v "^$ARTFNM|" > ${PWDDIR}/break.txt.tm
            mv ${PWDDIR}/break.txt.tm ${PWDDIR}/break.txt
        else
            read input?"�Ƿ�����ϵ��ļ�break.txt��[$ARTFNM]����ɹ���¼�����»���[y/n]��"
            case $input in
            Y|y)
                cat ${PWDDIR}/break.txt | grep -v "^$ARTFNM|" > ${PWDDIR}/break.txt.tm
                mv ${PWDDIR}/break.txt.tm ${PWDDIR}/break.txt
                ;;
            *)
                echo " "
                ;;
            esac
        fi
    fi
}

ProcBreakDel
ProcHbSqlData
ProcHbDiffCopy
ProcHbSameCopy
ProcHbDbOperate "$RUNDBNAME" "${ARTFDBOPERATE}/rundbhuanban.sql"
ProcHbDbOperate "$CFGDBNAME" "${ARTFDBOPERATE}/cfgdbhuanban.sql"

PrtMsg "\n[${ARTFNM}]�������...\n" "$BOLD" "$NORM"
