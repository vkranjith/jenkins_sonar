#!/bin/bash

# @author Ranjith V K
# @email ranjith_vk@yahoo.com

bin/magento setup:install --backend-frontname="manager" --db-host="localhost" --db-name="magento" --db-user="magento" --db-password="ranjith@123" --base-url="magento.localhost.com" --use-rewrites="1" --admin-user="ranjith" --admin-password="ranjith@123" --admin-email="ranjith_vk@yahoo.com" --admin-firstname="Ranjith" --admin-lastname="V K"
