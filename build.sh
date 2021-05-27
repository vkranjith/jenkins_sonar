#!/bin/bash

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
    ADMIN_PASSWORD=$(date +%s | sha256sum | base64 | head -c 16)
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

if [ ! $FILE_OWNER ]; then
    FILE_OWNER=magento
fi

if [ ! $SERVER_USER ]; then
    SERVER_USER=$FILE_OWNER
fi

if [ ! $SERVER_LOCATION ]; then
    set SERVER_LOCATION=/home/$FILE_OWNER/public_html/
fi

# remove trailing forward slash "/" from the path and add ".tmp"
SERVER_BUILD_LOCATION=$(echo $SERVER_LOCATION | sed 's/\/$//g').tmp


ssh $FILE_OWNER@$SERVER_ADDRESS << EOF
    if [ $STAGE_NAME == "Build" ]; then
        echo "Starting the Build Process..."

        cd $SERVER_BUILD_LOCATION
        echo "Current directory for build:"
        pwd

        # clean and pull the latest code
        git reset --hard HEAD
        # assuming the current branch is the correct branch to build and deploy
        git pull

        # clean up the vendor files and pull a fresh copy
        rm -rf vendor/*
        composer install
        chown -R $FILE_OWNER:$SERVER_USER ./

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
          bin/magento setup:install \
            --backend-frontname="$ADMIN_URL" \
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
        bin/magento deploy:mode:set developer
        bin/magento setup:di:compile
        bin/magento setup:static-content:deploy -f
        bin/magento deploy:mode:set $DEPLOY_MODE

        echo "Completed the Build Process..."
    fi

    if [ $STAGE_NAME == "Deploy" ]; then
        echo "Deploying the build files..."

        cd $SERVER_LOCATION
        bin/magento maintenance:enable

        # sync the build files
        rsync -rv $SERVER_BUILD_LOCATION/* $SERVER_LOCATION

        # remove all GIT files
        rm -rf .git/
        bin/magento set:up
        bin/magento maintenance:disable

        echo "Deployment complete";
    fi

EOF
