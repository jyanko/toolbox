#!/bin/bash

# script to check things like the pidfile, lockfile, running procs, etc.
#  - helps identify common gotchas seen when starting/stopping a jira or jira-servicedesk instance


# check for lockfile
test -e /var/atlassian/application-data/jira/.*.lock && LOCKFILE=$(ls /var/atlassian/application-data/jira/.*.lock) || LOCKFILE="none"

# capture pid
PIDVALUE=$(cat /opt/atlassian/jira/work/catalina.pid)

# check status
STATUS=$(curl -Is http://localhost:8080/status | grep HTTP)

echo "==========================================="
echo "Jira Check"
echo "==========================================="
echo "PIDVALUE   : $PIDVALUE"
echo "LOCKFILE   : $LOCKFILE"
echo "STATUS     : $STATUS"
echo "==========================================="
ps -fu jira
echo "==========================================="
echo "PID File   : /opt/atlassian/jira/work/catalina.pid"
echo "Log Path   : /var/atlassian/application-data/jira/log/atlassian-jira.log"
echo "Log Path   : /var/atlassian/application-data/jira/log/atlassian-servicedesk.log"
echo "Start Cmd  : /etc/init.d/jira start"
echo "Stop Cmd   : /etc/init.d/jira stop"
echo "==========================================="