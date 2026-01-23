#!/bin/bash

# script to check things like the pidfile, lockfile, running procs, etc.
#  - helps identify common gotchas seen when starting/stopping a jira or jira-servicedesk instance


# check for lockfile
test -e /var/atlassian/application-data/jira/.*.lock && LOCKFILE=$(ls /var/atlassian/application-data/jira/.*.lock) || LOCKFILE="none"

# capture pid
PIDVALUE=$(cat /opt/atlassian/jira/work/catalina.pid)

# check status
STATUS=$(curl -Is http://localhost:8080/status | grep HTTP)

echo -e "\033[34m===========================================\033[0m"
echo -e "\033[34mJira Check\033[0m"
echo -e "\033[34m===========================================\033[0m"
echo -e "\033[34mPIDVALUE   :\033[0m $PIDVALUE"
echo -e "\033[34mLOCKFILE   :\033[0m $LOCKFILE"
echo -e "\033[34mSTATUS     :\033[0m $STATUS"
echo -e "\033[34m===========================================\033[0m"
ps -fu jira
echo -e "\033[34m===========================================\033[0m"
echo -e "\033[34mPID File   :\033[0m /opt/atlassian/jira/work/catalina.pid"
echo -e "\033[34mLog Path   :\033[0m /var/atlassian/application-data/jira/log/atlassian-jira.log"
echo -e "\033[34mLog Path   :\033[0m /var/atlassian/application-data/jira/log/atlassian-servicedesk.log"
echo -e "\033[34mStart Cmd  :\033[0m /etc/init.d/jira start"
echo -e "\033[34mStop Cmd   :\033[0m /etc/init.d/jira stop"
echo -e "\033[34m===========================================\033[0m"