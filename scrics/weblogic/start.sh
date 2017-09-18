#!/bin/bash
usuario=`whoami`

if [ $usuario != "weblogic" ]
then
  echo "Se tiene que arrancar con usuario weblogic"
  exit 1
fi

. `dirname $0`/env
v_managed=`echo $0 |awk -F/ {'print $NF'} | cut -d"_"  -f2-`

if [ $v_managed == "nodemanager" ]
then
$v_wlst <<EOF
v_nodemanagerhome="`echo $v_nodemanagerhome`"
startNodeManager(NodeManagerHome=v_nodemanagerhome)
exit()
EOF
exit 0
fi

$v_wlst <<EOF
v_fileConfigConsole="`echo $v_fileConfigConsole`"
v_fileKeyConsole="`echo $v_fileKeyConsole`"
v_fileConfigNM="`echo $v_fileConfigNM`"
v_fileKeyNM="`echo $v_fileKeyNM`"

v_managed="`echo $v_managed`"
v_domain="`echo $v_domain`"
v_machine="`echo $v_machine`"
v_port="`echo $v_port`"
v_type="`echo $v_type`"
nmConnect(userConfigFile=v_fileConfigNM,userKeyFile=v_fileKeyNM,domainName=v_domain,host=v_machine,port=v_port,nmType=v_type)
nmStart(v_managed)
nmDisconnect()
exit()
EOF
