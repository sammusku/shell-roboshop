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
 MONGODB_HOST="mongodb.dev88s.online"
  
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

 dnf install maven -y   &>>$LOGS_FILE
 VALIDATE $? "installing maven"


id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "Creating system user"
   echo "$G Created the roboshop user $N"
else
   echo -e " roboshop user already exist in the system..$Y skipping $N "
fi

mkdir -p /app
VALIDATE $? "creating app directory"

rm -rf /app/*
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Downloading the shipping data"

cd /app 
unzip /tmp/shipping.zip
VALIDATE $? "unzip the shipping data from temp directory to app data"

mvn clean package &>>$LOGS_FILE
VALIDATE $? "install and build java dependencies"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "moving and remaning shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service  &>>$LOGS_FILE
VALIDATE $? "copying systemctl services"

systemctl daemon-reload
systemctl enable shipping  &>>$LOGS_FILE
systemctl start shipping  &>>$LOGS_FILE
VALIDATE $? "enable and start shipping"

dnf install mysql -y 
VALIDATE $? "installing mysql client"

if [ $? -ne 0 ]; then
    mysql -h mysql.dev88s.online -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
    mysql -h mysql.dev88s.online -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOGS_FILE
    mysql -h mysql.dev88s.online -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE
    VALIDATE $? "loading the schema,app data and master data for shipping application"
else
   echo -e "Data already available....$Y skipping $N"
fi
systemctl restart shipping
VALIDATE $? "restarting the shipping services"


