FROM debian:jessie

EXPOSE 749 88/udp

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update
RUN apt-get -qq install locales krb5-kdc krb5-admin-server
RUN apt-get -qq install vim 
RUN apt-get -qq clean

ENV DOMAIN ${DOMAIN:-mycompany.com}
ENV REALM ${REALM:-MYCOMPANY.COM}
ENV SUPPORTED_ENCRYPTION_TYPES ${SUPPORTED_ENCRYPTION_TYPES:-aes256-cts-hmac-sha1-96:normal}

# Principal Credentials - used by init-script.sh
ENV KADMIN_PRINCIPAL ${KADMIN_PRINCIPAL:-kadmin/admin}
ENV KADMIN_PASSWORD ${KADMIN_PASSWORD:-adminpassword}
ENV BROKER_PASSWORD ${BROKER_PASSWORD:-broker-secret}
ENV ZOOKEEPER_PASSWORD ${ZOOKEEPER_PASSWORD:-zookeeper-secret}
ENV CONNECT_PASSWORD ${CONNECT_PASSWORD:-connect-secret}
ENV C3_PASSWORD ${C3_PASSWORD:-controlcenter-secret}
ENV SR_PASSWORD ${SR_PASSWORD:-schemaregistry-secret}
ENV KSQL_PASSWORD ${KSQL_PASSWORD:-ksql-secret}
ENV ADMIN_PASSWORD ${ADMIN_PASSWORD:-admin-secret}
ENV CLIENT_PASSWORD ${CLIENT_PASSWORD:-client-secret}
ENV DATAGEN_PASSWORD ${DATAGEN_PASSWORD:-datagen-secret}
ENV JDBCSINK_PASSWORD ${JDBCSINK_PASSWORD:-jdbcsink-secret}

COPY init-script.sh /tmp/
CMD /tmp/init-script.sh

