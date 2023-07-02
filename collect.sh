#!/bin/bash

#This script was developed by Snowflake support, with minimal testing and error handling, in order
# to investigate JVM related performance issues The script must run as the user that owns the Java
# process in question. The script assumes that you can run the jstack command directly, if not,
# then you'll need to add the full path of the Java home's bin directory before jstack, for example:
# /usr/java/jdk1.8_182/bin/jstack

INTERVAL=2
ROOT_DIR=$(hostname)
mkdir -p ./$ROOT_DIR
CHILD_PID=()

trap cleanup SIGINT INT

cleanup() {

  echo "Killing child processes"

  for i in "${CHILD_PID[@]}"
  do
    kill -9 $i
  done;

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
     jstack $PID >> ./jstack.out
     #If jstack command has an exit status other than 0, then break out of the loop because
     #an error occurred. Most likely because the Java process stopped and doesn't exist anymore.
     if [ $? -ne 0 ]; then
        echo "Java Process ${PID} disappeared. Stopping collection for this process."
        break;
     fi
     sleep $INTERVAL
done
};

jps | while read a
do
 PID=$(echo $a | awk '{print $1}')
 CLASS_NAME=$(echo $a | awk '{print $2}')
 if [ ${CLASS_NAME} == $1 ]
  then
   collectData ${PID} &
   CHILD_PID+=( $! )
 fi
done

#Need to make sure the script process remains alive to listen for the interrupt signal to cleanup
while :
do
  echo "Press Ctrl+C to stop the script."
  a=1
done