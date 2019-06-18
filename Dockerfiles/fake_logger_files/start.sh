#!/bin/sh

NUMBER_OF_LOG_LINES=${NUMBER_OF_LOG_LINES:-300}

function fake_logger {
  FM=$1
  LG=$2
  echo Generating log type ${FM}, in file ${FM}_${LG}.log
  while true; do 
    flog --format ${FM} --type log --output ${FM}_${LG}.log --number ${NUMBER_OF_LOG_LINES} --overwrite --delay 1 >/dev/null
  done
}

function fake_csv_logger {
  TYP=$1
  SRV=$2
  EXT=$3

  header="CSVHeaderDate,CSVHeaderTime,CSVHeaderCSVFileType,CSVHeaderRandWord1,CSVHeaderRandNum1,CSVHeaderRandWord2,CSVHeaderRandNum2,CSVHeaderLineNum"
  while true; do
    exec 1>"csv_${TYP}_${SRV}.${EXT}"
    if [ "${TYP}" = "classic" ]; then printf "${header}\n"; fi
    for i in `seq 1 ${NUMBER_OF_LOG_LINES}`; do
      num1=$(od -N1 -An -i /dev/urandom | awk '{print $1}')
      num2=$(od -N1 -An -i /dev/urandom | awk '{print $1}')
      word1=`sed "${num1}q;d" /words`
      word2=`sed "${num2}q;d" /words`
      date_now=$(date +%Y-%m-%d)
      time_now=$(date +%H:%M:%S)
      printf "${date_now},${time_now},${TYP},${word1},${num1},${word2},${num2},Line_${i}_of_${NUMBER_OF_LOG_LINES}\n"
      sleep 1
    done
  done
}

cd /logs
for x in 1 2
do
  fake_logger rfc3164 fwd${x} &
  fake_logger rfc5424 fwd${x} &
  fake_logger apache_error fwd${x} &
  fake_logger apache_combined fwd${x} &
  fake_logger apache_common fwd${x} &
  fake_csv_logger classic fwd${x} csv &
  fake_csv_logger noheader fwd${x} csv &
  fake_csv_logger classic fwd${x} log &
  fake_csv_logger noheader fwd${x} log &
done

echo "Fake loggers started"
ps aux
# keep this process "alive" to keep the container running
cat
