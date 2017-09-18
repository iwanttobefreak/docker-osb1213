#!/bin/bash

/u01/weblogic/mid1213/oracle_common/common/bin/wlst.sh << EOF

createDomain("/u01/weblogic/mid1213/wlserver/common/templates/wls/wls.jar","/u01/weblogic/domains/osb","weblogic","weblogic01")   
readDomain('/u01/weblogic/domains/osb')
cd('/')
set('ProductionModeEnabled',true)
cd('/')
create('localhost','UnixMachine')
cd('Machines/localhost')
create('localhost', 'NodeManager')
cd('NodeManager/localhost')
set('NMType','Plain')
set('ListenAddress','127.0.0.1')

addTemplate('/u01/weblogic/mid1213/osb/common/templates/wls/oracle.osb_template_12.1.3.jar')

cd('/')
create('osb_cluster', 'Cluster')
cd('/Clusters/osb_cluster')
set('ClusterMessagingMode','unicast')
set('WeblogicPluginEnabled',true)
set('DefaultLoadAlgorithm','round-robin')

#Creamos Manejado2
cd('/')
create('osb_server2','Server')
cd('/Servers/osb_server2')
set('WeblogicPluginEnabled',true)
set('Cluster', 'osb_cluster')
set('Machine','localhost')


#Afegim manegat1 al cluster
cd('/Servers/osb_server1')
set('WeblogicPluginEnabled',true)
set('Cluster', 'osb_cluster')
set('Machine','localhost')



setServerGroups('osb_server2',['OSB-MGD-SVRS-COMBINED'])


v_datasources='LocalSvcTblDataSource','opss-data-source','opss-audit-viewDS','opss-audit-DBDS','mds-owsm','OraSDPMDataSource','wlsbjmsrpDataSource','SOADataSource','SOALocalTxDataSource'
for v_datasource in v_datasources:
  cd('/JDBCSystemResource/' + v_datasource + '/JdbcResource/' + v_datasource + '/JDBCDriverParams/NO_NAME_0')
  set('URL','jdbc:oracle:thin:@127.0.0.1:1521:DEV')
  set('PasswordEncrypted','weblogic01')
  cd('Properties/NO_NAME_0/Property/user')
  set('Value', get('Value').replace('DEV_', 'OSB_', 1))


updateDomain()
closeDomain()
exit()
EOF

sed -i 's/weblogic.StopScriptEnabled=false/weblogic.StopScriptEnabled=true/g' /u01/weblogic/domains/osb/nodemanager/nodemanager.properties
sed -i 's/SecureListener=true/SecureListener=false/g' /u01/weblogic/domains/osb/nodemanager/nodemanager.properties

sed -i -e 's/^JAVA_OPTIONS="${SAVE_JAVA_OPTIONS}"/JAVA_OPTIONS="-Djava.security.egd=file:\/dev\/.\/urandom ${SAVE_JAVA_OPTIONS}"/' /u01/weblogic/domains/osb/bin/startWebLogic.sh

/u01/weblogic/mid1213/oracle_common/common/bin/wlst.sh << EOF
startNodeManager(NodeManagerHome='/u01/weblogic/domains/osb/nodemanager')

nmConnect(username='weblogic', password='weblogic01',domainName='osb', host='127.0.0.1',port='5556', nmType='plain')

storeUserConfig(userConfigFile='/u01/weblogic/scrics/keys/NodeManagerConfig',userKeyFile='/u01/weblogic/scrics/keys/NodeManagerKey',nm='true')
y

nmConnect(userConfigFile='NodeManagerConfig', userKeyFile='NodeManagerKey', domainName='osb',host='127.0.0.1',port='5556',nmType='plain')

nmStart('AdminServer')

connect('weblogic','weblogic01', 't3://127.0.0.1:7001')

storeUserConfig(userConfigFile='/u01/weblogic/scrics/keys/AdminConfig',userKeyFile='/u01/weblogic/scrics/keys/AdminKey')
y

start('osb_server1')
start('osb_server2')

shutdown('osb_server1','Server',ignoreSessions='true')
shutdown('osb_server2','Server',ignoreSessions='true')
shutdown('AdminServer','Server',ignoreSessions='true')

stopNodeManager()
exit()
EOF

sed -i -e 's/^\(AdminURL=.*\)/AdminURL=http:\/\/127.0.0.1\\:7001/' /u01/weblogic/domains/osb/servers/osb_server1/data/nodemanager/startup.properties
sed -i -e 's/^\(AdminURL=.*\)/AdminURL=http:\/\/127.0.0.1\\:7001/' /u01/weblogic/domains/osb/servers/osb_server2/data/nodemanager/startup.properties

#sed -i -e 's/^\(replica.0.masterurl=.*\)/replica.0.masterurl=ldap\\:\/\/127.0.0.1\\:7001\//' /u01/weblogic/domains/osb/servers/AdminServer/data/ldap/conf/replicas.prop
#sed -i -e 's/^\(replica.1.masterurl=.*\)/replica.1.masterurl=ldap\\:\/\/127.0.0.1\\:7001\//' /u01/weblogic/domains/osb/servers/AdminServer/data/ldap/conf/replicas.prop
#sed -i -e 's/^\(replica.0.hostname=.*\)/replica.0.hostname=127.0.0.1/' /u01/weblogic/domains/osb/servers/AdminServer/data/ldap/conf/replicas.prop

rm /u01/weblogic/domains/osb/servers/*/data/nodemanager/*.url
