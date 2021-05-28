#!/bin/bash

# Set any variables
ENV_FILE=app/etc/env.php

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
    SERVER_LOCATION=/home/$FILE_OWNER/public_html/
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

        # clean the previously generated deployment and compiled files
        rm -r var/view_preprocessed/*
        rm -r pub/static/*/*
        rm -r generated/*/*
        rm -r var/log/*
        rm -rf var/report/*

        # set appropriate permissions for the build
        find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
        find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
        chown -R $FILE_OWNER:$SERVER_USER .
        chmod u+x bin/magento

        # clean up the vendor files and pull a fresh copy
        rm -rf vendor/*
        composer install
        chown -R $FILE_OWNER:$SERVER_USER ./

        # Check if the env.php file exists and if not, install the app
        if [ ! -f $ENV_FILE ]; then
          bin/magento setup:install \
            --db-host="$DATABASE_HOST" \
            --db-name="$DATABASE_NAME" \
            --db-user="$DATABASE_USERNAME" \
            --db-password="$DATABASE_PASSWORD" \
            --base-url="$APP_URL" \
            --use-rewrites="1" \
            --language=en_US \
            --currency=USD \
            --timezone=America/Chicago \
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
        echo "Deploying the build files..."
        rsync -ra $SERVER_BUILD_LOCATION/* $SERVER_LOCATION
        echo "Deploying files complete"

        # remove all GIT files
        rm -rf .git/

        bin/magento maintenance:disable

        echo "Deployment complete";
    fi

EOF
