#!/bin/bash

echo "Deploying the build files..."

# Check the variables and set default values if necessary
if [ ! $SERVER_USER ]; then
    SERVER_USER=magento
fi
if [ ! $SERVER_LOCATION ]; then
    SERVER_LOCATION=~/public_html/
fi

# enabling the maintenance mode
ssh $SERVER_USER@$SERVER_ADDRESS << EOF

cd $SERVER_LOCATION
bin/magento maintenance:enable

EOF

# remove the deployed env.php file before delpoying or syncing it to the actual environment
rm app/etc/env.php

# sync the combiled files
rsync -razv ./ $SERVER_USER@$SERVER_ADDRESS:~/public_html/

ssh $SERVER_USER@$SERVER_ADDRESS << EOF

cd $SERVER_LOCATION
echo "Current directory for deployment:"
pwd

# remove all GIT files
rm -rf .git/
bin/magento set:up
bin/magento maintenance:disable

EOF


echo "Deployment complete";
