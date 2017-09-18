#!/bin/bash
/u01/weblogic/scrics/start_nodemanager
nohup /u01/weblogic/scrics/start_osb_server1 >/dev/null 2>&1 &
nohup /u01/weblogic/scrics/start_osb_server2 >/dev/null 2>&1 &
/u01/weblogic/scrics/start_AdminServer
