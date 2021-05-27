#!/bin/bash

echo "Starting the Build Process..."

# Set any variables
ENV_FILE=app/etc/env.php

# Check the variables and set default values if necessary
if [ ! $ADMIN_URL ]; then
    # generate random admin url frontname
    ADMIN_URL=manage_$(date +%s | sha256sum | base64 | head -c 8)
fi

if [ ! $DATABASE_HOST ]; then
    DATABASE_HOST=localhost:3306
fi

if [ ! $DATABASE_NAME ]; then
    DATABASE_NAME=magento
fi

if [ ! $DATABASE_USERNAME ]; then
    DATABASE_USERNAME=magento
fi

if [ ! $DATABASE_PASSWORD ]; then
    DATABASE_PASSWORD=''
fi

if [ ! $APP_URL ]; then
    APP_URL=http://localhost/
fi

if [ ! $ADMIN_USER ]; then
    ADMIN_USER=admin_$(date +%s | sha256sum | base64 | head -c 8)
fi

if [ ! $ADMIN_PASSWORD ]; then
    ADMIN_PASSWORD=date +%s | sha256sum | base64 | head -c 16
fi

if [ ! $ADMIN_FNAME ]; then
    ADMIN_FNAME=admin
fi

if [ ! $ADMIN_LNAME ]; then
    ADMIN_LNAME=admin
fi

if [ ! $ELASTICSEARCH_VERSION ]; then
    ELASTICSEARCH_VERSION=elasticsearch7
fi

if [ ! $ELASTICSEARCH_HOST ]; then
    ELASTICSEARCH_HOST=localhost
fi

if [ ! $ELASTICSEARCH_PORT ]; then
    ELASTICSEARCH_PORT=9200
fi

if [ ! $DEPLOY_MODE ]; then
    DEPLOY_MODE=developer
fi

if [ ! $SERVER_USER ]; then
    SERVER_USER=magento
fi

if [ ! $SERVER_LOCATION ]; then
    SERVER_LOCATION=~/public_html/
fi

# remove trailing forward slash "/" from the path and add ".tmp"
SERVER_BUILD_LOCATION=$(echo $SERVER_LOCATION | sed 's/\/$//g').tmp

echo "Server Location..."
echo $SERVER_BUILD_LOCATION

ssh $SERVER_USER@$SERVER_ADDRESS << EOF

if [ ! -d "$SERVER_BUILD_LOCATION ]; then
    cp -r $SERVER_LOCATION $SERVER_BUILD_LOCATION
fi

cd $SERVER_BUILD_LOCATION
echo "Current directory for build:"
pwd

# clean up the vendor files and pull a fresh copy
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
  bin/magento setup:install --backend-frontname="$ADMIN_URL" \
    --db-host="$DATABASE_HOST" \
    --db-name="$DATABASE_NAME" \
    --db-user="$DATABASE_USERNAME" \
    --db-password="$DATABASE_PASSWORD" \
    --base-url="$APP_URL" \
    --use-rewrites="1" \
    --admin-user="$ADMIN_USER" \
    --admin-password="$ADMIN_PASSWORD" \
    --admin-email="$ADMIN_EMAIL" \
    --admin-firstname="$ADMIN_FNAME" \
    --admin-lastname="$ADMIN_LNAME" \
    --search-engine="$ELASTICSEARCH_VERSION" \
    --elasticsearch-host="$ELASTICSEARCH_HOST" \
    --elasticsearch-port="$ELASTICSEARCH_PORT"
fi

# deploy and compile
bin/magento app:config:import
bin/magento setup:upgrade
bin/magento deploy:mode:set $DEPLOY_MODE
bin/magento setup:di:compile
bin/magento setup:static-content:deploy -f

EOF

echo "Completed the Build Process..."
