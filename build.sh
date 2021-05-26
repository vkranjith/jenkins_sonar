#!/bin/bash

# env;

echo "Starting the Build Process..."

ENV_FILE=app/etc/env.php

pwd
rm -rf vendor/*
composer install
# chown -R jenkins:jenkins ./

# set appropriate permissions for the build
chmod +x bin/magento


# clean the previously generated deployment and compiled files
rm -r var/view_preprocessed/*
rm -r pub/static/*/*
rm -r generated/*/*
rm -r var/log/*
rm -rf var/report/*

# Check if the env.php file exists and if not, install the app
if [ ! -f $ENV_FILE ]; then
  bin/magento setup:install --backend-frontname="manager" --db-host="localhost" --db-name="magento" --db-user="magento" --db-password="ranjith@123" --base-url="http://magento.localhost.com/" --use-rewrites="1" --admin-user="ranjith" --admin-password="ranjith@123" --admin-email="ranjith_vk@yahoo.com" --admin-firstname="Ranjith" --admin-lastname="V K" --search-engine="elasticsearch7" --elasticsearch-host="localhost" --elasticsearch-port="9200"
fi

# deploy and compile
bin/magento app:config:import
bin/magento setup:upgrade
bin/magento deploy:mode:set developer
bin/magento setup:di:compile
bin/magento setup:static-content:deploy -f



echo "Completed the Build Process..."

