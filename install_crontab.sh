#!/bin/bash
tmp=`tmpnam`
crontab -l > $tmp
echo "0 20 * * 0 ${pwd}/a214_driver.sh" >> $tmp
crontab $tmp

