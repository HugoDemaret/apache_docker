#!/bin/bash

# Constant definition (mainly GitHub repositary) :
PGSQL_image="https://raw.githubusercontent.com/HugoDemaret/apache_docker/main/docker-compose-auto-pgsql.yml"
MYSQL_image="https://raw.githubusercontent.com/HugoDemaret/apache_docker/main/docker-compose-auto-mysql.yml"
PHPini_image="https://raw.githubusercontent.com/HugoDemaret/apache_docker/main/php.ini"
VERSION='0.0.1'

# Fancy script presentation (half the coding time this was spent for this beautiful title!)
cat << 'EOF'
 _____                _            _             
/ __  \        _     | |          | |            
`' / /' __ _ _| |_ __| | ___   ___| | _____ _ __ 
  / /  / _` |_   _/ _` |/ _ \ / __| |/ / _ \ '__|
./ /__| (_| | |_|| (_| | (_) | (__|   <  __/ |   
\_____/\__,_|     \__,_|\___/ \___|_|\_\___|_|   
                                                 
EOF                                 
echo "Version : $VERSION"

# User awareness about damage
echo "Be aware that running this script can damage your system if not executed in a clean and safe
environment. If you encounter any problem, please report them on the github repo."
echo "Github repository link :"
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

# Downloading php.ini
wget $PHPini_image
mv php.ini ./config_files/php.ini

# Setting up database's dependencies in Dockerfile and php.ini
if ["$DB_choice" -eq "1"]
then
# Installing dependencies for mysql
echo "RUN docker-php-ext-install pdo pdo_mysql msqli" >> Dockerfile
wget $MYSQL_image
mv docker-compose-auto-mysql.yml docker-compose.yml

# Technically only for windows users but resolved a problem for me (why ?)
sed -i -e"s/\;extension\=php_pdo_mysql.dll/extension\=php_pdo_mysql.dll/g" ./config_files/php.ini
sed -i -e"s/\;extension\=php_mysqli.dll/extension\=php_mysqli.dll/g" ./config_files/php.ini

elif ["$DB_choice" -eq "2"]
then
# Installing dependencies for pgsql
echo "RUN docker-php-ext-instal pdo pdo_pqsql" >> Dockerfile
wget $PGSQL_image
mv docker-compose-auto-pgsql.yml docker-compose.yml

# Technically only for windows users but resolved a problem for me (why ?)
sed -i -e"s/\;extension\=php_pdo_pgsql.dll/extension\=php_pdo_pgsql.dll/g" ./config_files/php.ini
sed -i -e"s/\;extension\=php_pgsql.dll/extension\=php_pgsql.dll/g" ./config_files/php.ini

else
# Incorrect information
echo "Error : $DB_choice is not included. "
exit
fi
# Final Dockerfile configuration
echo "COPY ./config_files /etc/php/7.3/cli/php.ini"
echo "EXPOSE 80"
# Configuration of docker-compose.yml
echo "Starting configuration of docker-compose.yml "
echo "We recommend using strong password with at least 12 characters (and <100)"

read -p "Enter website container name " WEBCont_Name
read -p "Enter database container name " DBCont_Name
read -p "Enter webservice name " WEBS_Name
read -p "Enter database service name " DBS_Name
read -p "Enter a database name " DB_Name
read -p "Enter database username " USER_Name
read -p "Enter database user's password " USER_Passwd

# Sets root password for mysql, continues if pgsql
if ["$DB_choice" -eq "1"]
then
# For mysql only
echo "For mysql only "
read -p "Enter root password for database " ROOT_Passwd
sed -i -e"s/root.password/$ROOT_Passwd/g" docker-compose.yml
else
continue
fi
# URL modification
read -p "Enter your website URL " URL

# Replacing default docker-compose.yml config by user inputs:
sed -i -e"s/website.container.name/$WEBCont_Name/g" docker-compose.yml
sed -i -e"s/database_servee.container.name/$DBCont_Name/g" docker-compose.yml
sed -i -e"s/websiteservice_name/$WEBS_Name/g" docker-compose.yml
sed -i -e"s/databaseservice_name/$DBS_Name/g" docker-compose.yml
sed -i -e"s/database.name/$DB_Name/g" docker-compose.yml
sed -i -e"s/user.name/$USER_Name/g" docker-compose.yml
sed -i -e"s/user.password/$USER_Passwd/g" docker-compose.yml
sed -i -e"s/your.url.url/$URL/g" docker-compose.yml
# Setting volume path
sed -i -e"s/path.to.website/.\/website/g" docker-compose.yml
sed -i -e"s/path.to.db/.\/database/g" docker-compose.yml

# Creates the start.sh script (that starts docker-compose.yml and updates permissions)
START_dmg = ls | grep -E 'docker-compose.yml|Dockerfile' | wc -l
if ["$START_dmg" -ne "0"]
then
echo "ERROR : start.sh already exists. Aborting to avoid damage "
exit
fi
echo "Beginning configuration of start.sh script... "
touch start.sh
PATH="$(pwd)\/website"
echo '#!bin/bash' >> start.sh
echo 'echo "Updating permissions..."' >> start.sh
echo "chown -R 33\:33 $PATH" >> start.sh
echo 'echo "Starting the service !"' >> start.sh
echo "docker-compose up -d" >> start.sh
echo 'echo "Done!"' >> start.sh
echo "start.sh configuration complete!"

echo "Configuration complete! Do not forget to install traefik!"
