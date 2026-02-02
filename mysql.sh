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

dnf install mysql-server -y &>>$LOGS_FILE
VALIDATE $? "installing mysql"

systemctl enable mysqld &>>$LOGS_FILE
systemctl start mysqld &>>$LOGS_FILE
VALIDATE $? "enable and start mysql"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "setup root password"