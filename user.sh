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

dnf module list nodejs -y &>>$LOGS_FILE
VALIDATE $? "List of avaialble nodejs versions"

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disable nodejs default  version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "enable nodejs:20 version"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "installing Nodejs 20"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "Creating system user"
   echo " $G Created the roboshop user $N "
else
   echo -e " roboshop user already exist in the system..$Y skipping $N "
fi

mkdir -p /app
VALIDATE $? "creating app directory"


curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading user data"

cd /app
VALIDATE $? "moving to app directory"

rm -rf /app/*
VALIDATE $? "removing already existed data from app"

unzip /tmp/user.zip &>>$LOGS_FILE
VALIDATE $? "unzip user data from temp directory to app directory"

npm install 
VALIDATE $? "installing the nodejs dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "copying the system services"

systemctl daemon-reload
VALIDATE $? "reloading the changes"

systemctl enable user &>>$LOGS_FILE
VALIDATE $? "enable user"

systemctl start user &>>LOGS_FILE
VALIDATE $? "start user server"


systemctl restart user &>>$LOGS_FILE
VALIDATE $? "restarting the user"


