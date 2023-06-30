#!/bin/bash

#This script was developed by Snowflake support, with minimal testing and error handling, in order to investigate JVM related performance issues 
#The script must run as the root user in order to run Java's jstack command by sudoing as the user
#that owns the Java process in question. The script assumes that you can run the jstack command directly, if not, then you'll need
#to add the full path of the Java home's bin directory before jstack, for example: /usr/java/jdk1.8_182/bin/jstack
#This script takes two arguments, PID of the Java process to inspect and username that owns the Java process.

INTERVAL=2
ROOT_DIR=$(hostname)
mkdir -p ./$ROOT_DIR

trap cleanup 1 2 3 6 SIGINT 

cleanup() {

  echo "Exiting script: ctrl+c issued."
  echo "Copying /var/log/messages"
  cp /var/log/messages ./$ROOT_DIR/
  echo "Copying /var/log/dmesg"
  dmesg -T >> ./$ROOT_DIR/dmesg
  echo "Zipping up directory: $ROOT_DIR"
  tar cvzf ./$ROOT_DIR.tar.gz ./$ROOT_DIR/*
  echo "Cleanup: Deleting directory $ROOT_DIR"
  rm -Rf ./$ROOT_DIR
  echo "Please locate the file $ROOT_DIR.tar.gz and upload it to the case"
  exit 1
}

collectData() {

PID=$1

mkdir -p ./$ROOT_DIR/$PID
cd ./$ROOT_DIR/$PID

echo "Collecting data from Java process with PID $PID run by user $USER"
echo "Host: $(uname -a)" >> ./top.out
echo "Java Process: $PID" >> ./top.out
echo "User ID: $USER" >> ./top.out

echo "Host: $(uname -a)" >> ./topH.out
echo "Java Process: $PID" >> ./topH.out
echo "User ID: $USER" >> ./topH.out

echo "Host: $(uname -a)" >> ./ps.out
echo "Java Process: $PID" >> ./ps.out
echo "User ID: $USER" >> ./ps.out
ps -ef >> ./ps.out

echo "Host: $(uname -a)" >> ./vmstat.out
echo "Java Process: $PID" >> ./vmstat.out
echo "User ID: $USER" >> ./vmstat.out


while :
do
     top -b -n 1 >> ./top.out
     top -p $PID -b -H -n1 >> ./topH.out
     vmstat -wt >> ./vmstat.out
     jstack -l $PID >> ./jstack.out
     sleep $INTERVAL
done
};

jps | while read a
do
 PID=$(echo $a | awk '{print $1}')
 CLASS_NAME=$(echo $a | awk '{print $2}')
 if [ -z "$CLASS_NAME" ]
  then
   collectData ${PID}
 fi
done
