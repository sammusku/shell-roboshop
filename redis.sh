#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


   if [ $USER_ID -ne 0 ]; then 
      echo -e "$R please run the script with root user $N" &>>$LOGS_FILE
      exit 1
   fi

mkdir -p $LOGS_FOLDER

VALIDATE() {
   if [ $1 -ne 0 ]; then
   echo -e " $2.......$R failed $N " | tee -a $LOGS_FILE
   exit 1 
   else 
   echo -e " $2.......$G success $N " | tee -a $LOGS_FILE
   fi
}


dnf module disable redis -y
dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "enable redis 7"

dnf install redis -y &>>$LOGS_FILE
VALIDATE $? "install redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no'  /etc/redis/redis.conf
VALIDATE $? "Allowing remote connection"

systemctl enable redis &>>$LOGS_FILE
systemctl start redis  &>>$LOGS_FILE
VALIDATE $? "enable and start redis"