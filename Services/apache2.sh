#!/bin/bash
echo "USE=\"apache2 php\"" >> /etc/portage/make.conf
emerge www-servers/apache

rc-service apache2 start
#no php
