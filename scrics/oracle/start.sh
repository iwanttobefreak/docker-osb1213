export ORACLE_HOME=/u01/oracle/app/oracle/product/12.1.0/dbhome_1
export PATH=$PATH:/u01/oracle/app/oracle/product/12.1.0/dbhome_1/bin/
export ORACLE_SID=dev

lsnrctl start listener

sqlplus "/as sysdba" << EOF
startup
EOF
