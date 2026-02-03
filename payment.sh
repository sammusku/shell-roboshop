#!/bin/bash


# Get the current user ID
 USER_ID=$(id -u)

 # Logging Configuration
 LOGS_FOLDER="/var/log/shell-roboshop"
 LOGS_FILE="$LOGS_FOLDER/$0.log"

 # Used to display colored messages for better readability
 R="\e[31m"
 G="\e[32m"
 Y="\e[33m"
 N="\e[0m"

 SCRIPT_DIR=$PWD
  
# Root User Validation
# =============================
# Check if the script is being run as root user
# If not, print an error message and exit

if [ $USER_ID -ne 0 ]; then
 echo -e "$R please use root user to run the script $N" | tee -a $LOGS_FILE
 exit 1
fi

# Create the logs directory if it does not already exist
mkdir -p $LOGS_FOLDER

VALIDATE() {
    if [ $1 -ne 0 ]; then
       echo -e "$Y $2 $N----- $R failure $N" | tee -a $LOGS_FILE
       exit 1
    else
       echo -e "$Y $2 $N------$G success $N " | tee -a $LOGS_FILE
    fi
}

dnf install python3 gcc python3-devel -y
VALIDATE $? "installing python3"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "roboshop user created"
else 
   echo -e "user already exist...$Y skipping $N "
fi

mkdir -p /app
VALIDATE $? "create app directory if it does not exist"

rm -rf /app/*
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading payment data"

cd /app 
unzip /tmp/payment.zip
VALIDATE $? "unzip payment data"

pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "install dependencies of python by requirements.txt"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "copying systemctl services"

systemctl daemon-reload
systemctl enable payment  &>>$LOGS_FILE
systemctl start payment &>>$LOGS_FILE
VALIDATE $? "enable and start payment"



