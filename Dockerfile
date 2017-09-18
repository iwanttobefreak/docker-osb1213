FROM oraclelinux

RUN yum install -y oracle-rdbms-server-12cR1-preinstall sudo unzip libXtst libXrender sudo bc net-tools libaio 

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/weblogic && \
    echo "weblogic:x:${uid}:${gid}:Weblogic,,,:/home/weblogic:/bin/bash" >> /etc/passwd && \
    echo "weblogic:x:${uid}:" >> /etc/group && \
    echo "weblogic ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/weblogic && \
    chmod 0440 /etc/sudoers.d/weblogic && \
    chown ${uid}:${gid} -R /home/weblogic

RUN echo "oracle ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/oracle && \
    chmod 0440 /etc/sudoers.d/oracle

RUN mkdir -p /u01/oracle/pogramas
RUN mkdir -p /u01/oracle/scrics

RUN mkdir -p /u01/weblogic/pogramas
RUN mkdir -p /u01/weblogic/scrics

COPY install/* /u01/oracle/pogramas/
COPY install/* /u01/weblogic/pogramas/
COPY scrics/oracle/* /u01/oracle/scrics/
COPY scrics/weblogic/* /u01/weblogic/scrics/

RUN chown weblogic. /u01/weblogic/scrics/*
RUN chmod +x /u01/weblogic/scrics/*sh

RUN chmod +x /u01/oracle/scrics/*

RUN chown -R oracle. /u01/oracle
RUN chown -R weblogic. /u01/weblogic

USER oracle

RUN cd /u01/oracle/pogramas && \
    curl -O http://172.17.0.1:8080/bbdd/linuxamd64_12102_database_1of2.zip && \
    curl -O http://172.17.0.1:8080/bbdd/linuxamd64_12102_database_2of2.zip && \
    unzip linuxamd64_12102_database_1of2.zip && \
    unzip linuxamd64_12102_database_2of2.zip && \
    cd /u01/oracle/pogramas/database && \
    ./runInstaller -waitforcompletion -showProgress -logLevel finest -ignoreSysPrereqs -ignorePrereq -silent -responseFile /u01/oracle/pogramas/response_BBDD.rsp && \
    cd /u01 && rm /u01/oracle/pogramas/linuxamd64_12102_database_1of2.zip /u01/oracle/pogramas/linuxamd64_12102_database_2of2.zip && rm -rf /u01/oracle/pogramas/database && \
    /u01/oracle/app/oracle/product/12.1.0/dbhome_1/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname dev -sid dev -responseFile NO_VALUE -characterSet AL32UTF8 -memoryPercentage 20 -emConfiguration NONE -sysPassword oracle -systemPassword oracle 

USER weblogic

###############
# Install OSB #
###############

#Install JAVA
RUN cd /u01/weblogic/pogramas && \
    curl -O http://172.17.0.1:8080/java/jdk-7u79-linux-x64.tar.gz && \
    tar -xzvf jdk-7u79-linux-x64.tar.gz && \
    mv jdk1.7.0_79/ /u01/weblogic/java && \
    rm /u01/weblogic/pogramas/jdk-7u79-linux-x64.tar.gz

#Install Infrastructure
RUN cd /u01/weblogic/pogramas && \
    curl -O http://172.17.0.1:8080/wls/fmw_12.1.3.0.0_infrastructure.jar && \
    /u01/weblogic/java/bin/java -Djava.io.tmpdir=/u01/weblogic/tmp -Xmx1024m -jar /u01/weblogic/pogramas/fmw_12.1.3.0.0_infrastructure.jar -silent -responseFile /u01/weblogic/pogramas/response.rsp -invPtrLoc /u01/weblogic/pogramas/inventory.loc && \
    sed -i -e 's/^JVM_ARGS="/JVM_ARGS="-Djava.security.egd=file:\/dev\/.\/urandom /' /u01/weblogic/mid1213/oracle_common/common/bin/wlst.sh && \
    rm /u01/weblogic/pogramas/fmw_12.1.3.0.0_infrastructure.jar

#Install OSB
RUN cd /u01/weblogic/pogramas && \
    curl -O http://172.17.0.1:8080/osb/fmw_12.1.3.0.0_osb.jar && \
    /u01/weblogic/java/bin/java -Djava.io.tmpdir=/u01/weblogic/tmp -Xmx1024m -jar /u01/weblogic/pogramas/fmw_12.1.3.0.0_osb.jar -silent -invPtrLoc /u01/weblogic/pogramas/inventory.loc -ignoreSysPrereqs -responseFile /u01/weblogic/pogramas/response_osb.rsp && \
    rm /u01/weblogic/pogramas/fmw_12.1.3.0.0_osb.jar

USER oracle

RUN /u01/oracle/scrics/start.sh && \
    sudo su - weblogic -c "export JAVA_HOME=/u01/weblogic/java && \
    /u01/weblogic/mid1213/oracle_common/bin/rcu -silent -createRepository -connectString 127.0.0.1:1521:DEV -dbUser sys -dbRole SYSDBA -schemaPrefix OSB -component IAU -component MDS -component IAU_APPEND -component IAU_VIEWER -component OPSS -component STB -component WLS -component UCSUMS -component SOAINFRA -component ESS -f < /u01/weblogic/pogramas/passwordfile.txt"

USER oracle
RUN /u01/oracle/scrics/start.sh && \
    sudo su - weblogic -c "/u01/weblogic/scrics/create_domain.sh && \
    cd /u01/weblogic/scrics && \
    ln -s start.sh start_nodemanager && \
    ln -s start.sh start_AdminServer && \
    ln -s start.sh start_osb_server1 && \
    ln -s start.sh start_osb_server2"

CMD /u01/oracle/scrics/start.sh && \
    sudo su - weblogic -c "/u01/weblogic/scrics/start_ALL.sh" && \
    bash
