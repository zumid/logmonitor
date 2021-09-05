#!/bin/bash

#### Setting ####

LIST_FILE=./monitor.list
TMPFILE=./tmp/monitor.tmp
LOGFILE=./log/`basename $0 .sh`_`date "+%Y%m%d"`.log
CHECKSTR="error"

#### function ####

function error_notify () {
	python3 /opt/scripts/slack_notify/alert.py "$1"	
	echo "$1"
}

#### main ####

exec 1> >(
  while read -r l; do echo "[$(date +"%Y-%m-%d %H:%M:%S")] $l"; done \
    | tee -a $LOGFILE
)
exec 2> >(
  while read -r l; do echo "[$(date +"%Y-%m-%d %H:%M:%S")] $l"; done \
    | tee -a $LOGFILE
)

echo "[ INFO] log check start"

cd `dirname $0`

if [ ! -f ${LIST_FILE} ]; then
#	monitor_list=`cat ${LIST_FILE}`
#else
	echo "[ERROR] ${LIST_FILE} does not exist."
	exit
fi

while read line
do
	echo ${line} | grep -v '^\s*#' | grep -v '^\s*$' > /dev/null
	if [ $? -ne 0 ]; then
		continue
	fi

	if [ -f ${TMPFILE} ];then	
		old_row=`cat ${TMPFILE} | grep "${line}" | awk -F "\t" '{print $2}'`
		if [ -z ${old_row} ]; then 
			old_row=0
		fi
	else
		old_row=0
	fi
	file_path=`echo $(eval echo ${line})`
	echo "[ INFO] Check start <${file_path}>"
	# 存在チェック
	if [ ! -f ${file_path} ];then
		echo "[ INFO] ${file_path} does not exist yet."
		continue
	fi
	row=`cat ${file_path} | wc -l`

	echo "row=${row} old_row=${old_row}"
	if [ ${old_row} -le ${row} ]; then
		search_row=$((old_row + 1))
	else
		search_row=0
	fi
	error_mes=`tail -n +${search_row} ${file_path} | egrep -i "${CHECKSTR}"`
	error_notify "$error_mes"

	echo "row=${row} old_row=${old_row}"
	echo -e "${line}\t${row}" >> "${TMPFILE}2"
done < ${LIST_FILE} 

if [ -f ${TMPFILE}2 ];then
	mv -f ${TMPFILE}2 ${TMPFILE}
else
	echo "[ WARN] ${TMPFILE}2 does not exist."
fi
echo "[ INFO] log check finished"
