#!/bin/bash

env;

echo "Deploying the build files..."

# ssh magento@192.168.56.104 touch $(date +filename%s.txt)

# enabling the maintenance mode
ssh magento@192.168.56.104 << EOF

cd public_html/
bin/magento maintenance:enable

EOF

# echo $GIT_URL;
rm app/etc/env.php

# sync the combiled files
rsync -razOev ./ magento@192.168.56.104:~/public_html/

ssh magento@192.168.56.104 << EOF

cd public_html/
echo "Current directory for deployment:"
pwd

# remove all GIT files
rm -rf .git/

bin/magento set:up
# rm -rf jenkins_build
# cp -r jenkins jenkins_build
# cd jenkins_build
# git pull
# git status

bin/magento maintenance:disable

EOF


echo "Deployment complete";
