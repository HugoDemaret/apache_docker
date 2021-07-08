#!/bin/bash
# Constant definition :
PGSQL_image="https://raw.githubusercontent.com/HugoDemaret/apache_docker/main/docker-compose-auto-pgsql.yml"
MYSQL_image="https://raw.githubusercontent.com/HugoDemaret/apache_docker/main/docker-compose-auto-mysql.yml"
# Fancy script presentation (half the time coding this was spent for this beautiful title!)

# User awareness about damage
echo "Be aware that running this script can damage your system if not executed in a clean and safe
environment. If you encounter any problem, please report them on the github repo."
echo "Git repository link :"
echo 'https://github.com/HugoDemaret/apache_docker/tree/main'

# Checks for dependencies (docker, docker-compose, git)
which docker >/dev/null || (sudo apt-get install docker docker-compose)
which git >/dev/null || (sudo apt-get install git)

# Checks if a docker-compose.yml and Dockerfile exists in the current directory. If yes, abort (to avoid damage)
DOCK_dmg = ls | grep -E 'docker-compose.yml\|Dockerfile' | wc -l
if ["$DOCK_dmg" -ne "0"]
then
echo "ERROR : A Dockerfile and\/or docker-compose.yml already exists."
echo "Aborting to avoid damage."
exit
else
continue
fi
# Creating the working directory
mkdir apache_webservice
cd apache_webservice
mkdir database website config_files
# Creating Dockerfile and its configuration
touch Dockerfile
echo "FROM php:apache" >> Dockerfile
echo "RUN sudo apt-get update -y && sudo apt-get upgrade -y" >> Dockerfile
echo "Chose your database between:"
echo "1: MYSQL"
echo "2: POSTGRESQL"
read -p "Enter the number corresponding to your choice :" $DB_choice
echo "You have chosen $DB_choice"
#Setting up database's dependencies in Dockerfile
if ["$DB_choice" -eq "1"]
then
echo "RUN docker-php-ext-install pdo pdo_mysql msqli" >> Dockerfile
wget $MYSQL_image
mv docker-compose-mysql.yml docker-compose.yml
elif ["$DB_choice" -eq "2"]
then
echo "RUN docker-php-ext-instal pdo pdo_pqsql" >> Dockerfile
wget $PGSQL_image

else
echo "Error : $DB_choice is not included."
exit
fi
