FROM confluentinc/cp-server-connect:7.1.1

USER root

RUN confluent-hub install --no-prompt jcustenborder/kafka-config-provider-vault:latest
RUN cp /usr/share/confluent-hub-components/jcustenborder-kafka-config-provider-vault/lib/*.jar /usr/share/java/confluent-security/connect

USER appuser
