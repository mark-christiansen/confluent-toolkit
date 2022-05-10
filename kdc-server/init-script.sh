# Based on https://github.com/ist-dsi/docker-kerberos/blob/master/kdc-kadmin/init-script.sh
# by Simão Martins and David Duarte
#!/bin/bash

mkdir -vp /var/log/kerberos/
echo "==================================================================================="
echo "==== Kerberos KDC and Kadmin ======================================================"
echo "==================================================================================="
KADMIN_PRINCIPAL_FULL=$KADMIN_PRINCIPAL@$REALM

echo "REALM: $REALM"
echo "KADMIN_PRINCIPAL_FULL: $KADMIN_PRINCIPAL_FULL"
echo "KADMIN_PASSWORD: $KADMIN_PASSWORD"
echo ""

echo "==================================================================================="
echo "==== /etc/krb5kdc/kadm5.acl ======================================================="
echo "==================================================================================="
tee /etc/krb5kdc/kadm5.acl <<EOF
$KADMIN_PRINCIPAL_FULL *
EOF
echo ""

echo "==================================================================================="
echo "==== Creating realm ==============================================================="
echo "==================================================================================="
MASTER_PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)
# This command also starts the krb5-kdc and krb5-admin-server services
krb5_newrealm <<EOF
$MASTER_PASSWORD
$MASTER_PASSWORD
EOF
echo ""

echo "==================================================================================="
echo "==== Creating default principals in the acl ======================================="
echo "==================================================================================="
echo "Adding $KADMIN_PRINCIPAL principal"
kadmin.local -q "delete_principal -force $KADMIN_PRINCIPAL_FULL"
echo ""
kadmin.local -q "addprinc -pw $KADMIN_PASSWORD $KADMIN_PRINCIPAL_FULL"
echo ""

echo "Adding broker principal #1"
kadmin.local -q "delete_principal -force kafka/kafka1.$DOMAIN@$REALM"
echo ""
kadmin.local -q "addprinc -pw $BROKER_PASSWORD kafka/kafka1.$DOMAIN@$REALM"
echo ""
echo "Adding broker principal #2"
kadmin.local -q "delete_principal -force kafka/kafka2.$DOMAIN@$REALM"
echo ""
kadmin.local -q "addprinc -pw $BROKER_PASSWORD kafka/kafka2.$DOMAIN@$REALM"
echo ""
echo "Adding broker principal #3"
kadmin.local -q "delete_principal -force kafka/kafka3.$DOMAIN@$REALM"
echo ""
kadmin.local -q "addprinc -pw $BROKER_PASSWORD kafka/kafka3.$DOMAIN@$REALM"
echo ""
echo "Adding load balancer principal"
kadmin.local -q "delete_principal -force kafka/lb.$DOMAIN@$REALM"
echo ""
kadmin.local -q "addprinc -pw $BROKER_PASSWORD kafka/lb.$DOMAIN@$REALM"
echo ""
echo "Adding zkclient principal"
kadmin.local -q "delete_principal -force zkclient@$REALM"
echo ""
kadmin.local -q "addprinc -pw $BROKER_PASSWORD zkclient@$REALM"
echo ""

echo "Adding zookeeper principal #1"
kadmin.local -q "delete_principal -force zookeeper/zoo1.$DOMAIN@$REALM"
echo ""
kadmin.local -q "addprinc -pw $ZOOKEEPER_PASSWORD zookeeper/zoo1.$DOMAIN@$REALM"
echo ""
echo "Adding zookeeper principal #2"
kadmin.local -q "delete_principal -force zookeeper/zoo2.$DOMAIN@$REALM"
echo ""
kadmin.local -q "addprinc -pw $ZOOKEEPER_PASSWORD zookeeper/zoo2.$DOMAIN@$REALM"
echo ""
echo "Adding zookeeper principal #3"
kadmin.local -q "delete_principal -force zookeeper/zoo3.$DOMAIN@$REALM"
echo ""
kadmin.local -q "addprinc -pw $ZOOKEEPER_PASSWORD zookeeper/zoo3.$DOMAIN@$REALM"
echo ""

echo "Adding connect principal #1"
kadmin.local -q "delete_principal -force connect1@$REALM"
echo ""
kadmin.local -q "addprinc -pw $CONNECT_PASSWORD connect1@$REALM"
echo ""
echo "Adding connect principal #2"
kadmin.local -q "delete_principal -force connect2@$REALM"
echo ""
kadmin.local -q "addprinc -pw $CONNECT_PASSWORD connect2@$REALM"
echo ""
echo "Adding connect principal #3"
kadmin.local -q "delete_principal -force connect3@$REALM"
echo ""
kadmin.local -q "addprinc -pw $CONNECT_PASSWORD connect3@$REALM"
echo ""

echo "Adding c3 principal"
kadmin.local -q "delete_principal -force c3@$REALM"
echo ""
kadmin.local -q "addprinc -pw $C3_PASSWORD c3@$REALM"
echo ""

echo "Adding Schema Registry principal #1"
kadmin.local -q "delete_principal -force schema1@$REALM"
echo ""
kadmin.local -q "addprinc -pw $SR_PASSWORD schema1@$REALM"
echo ""
echo "Adding Schema Registry principal #2"
kadmin.local -q "delete_principal -force schema2@$REALM"
echo ""
kadmin.local -q "addprinc -pw $SR_PASSWORD schema2@$REALM"
echo ""
echo "Adding Schema Registry principal #3"
kadmin.local -q "delete_principal -force schema3@$REALM"
echo ""
kadmin.local -q "addprinc -pw $SR_PASSWORD schema3@$REALM"
echo ""

echo "Adding KSQLDB principal #1"
kadmin.local -q "delete_principal -force ksql1@$REALM"
echo ""
kadmin.local -q "addprinc -pw $KSQL_PASSWORD ksql1@$REALM"
echo ""

echo "Adding admin principal for producers/consumers"
kadmin.local -q "delete_principal -force admin@$REALM"
echo ""
kadmin.local -q "addprinc -pw $ADMIN_PASSWORD admin@$REALM"
echo ""

echo "Adding client principal for producers/consumers"
kadmin.local -q "delete_principal -force client@$REALM"
echo ""
kadmin.local -q "addprinc -pw $CLIENT_PASSWORD client@$REALM"
echo ""

echo "Adding datagen principal"
kadmin.local -q "delete_principal -force datagen@$REALM"
echo ""
kadmin.local -q "addprinc -pw $DATAGEN_PASSWORD datagen@$REALM"
echo ""

echo "Adding jdbc principal"
kadmin.local -q "delete_principal -force jdbcsink@$REALM"
echo ""
kadmin.local -q "addprinc -pw $JDBCSINK_PASSWORD jdbcsink@$REALM"
echo ""

echo "Principals in KDC"
kadmin.local -q "listprincs"

echo "==================================================================================="
echo "==== Creating keytabs ============================================================="
echo "==================================================================================="
echo "Cleaning up old and creating new keytabs."
rm -fv /keytabs/*.keytab

echo "Adding broker principals + zkclient to kafka.keytab"
kadmin.local -q "ktadd -k /keytabs/kafka.keytab kafka/kafka1.$DOMAIN@$REALM"
kadmin.local -q "ktadd -k /keytabs/kafka.keytab kafka/kafka2.$DOMAIN@$REALM"
kadmin.local -q "ktadd -k /keytabs/kafka.keytab kafka/kafka3.$DOMAIN@$REALM"
kadmin.local -q "ktadd -k /keytabs/kafka.keytab zkclient@$REALM"
# Add load balancer principal alias for clients using lb url
kadmin.local -q "ktadd -k /keytabs/kafka.keytab kafka/lb.$DOMAIN@$REALM"

# echo "Creating zkclient keytab"
# kadmin.local -q "ktadd -k /keytabs/zkclient.keytab zkclient@$REALM"

echo "Adding zookeeper principals to zoo.keytab"
kadmin.local -q "ktadd -k /keytabs/zoo.keytab zookeeper/zoo1.$DOMAIN@$REALM"
kadmin.local -q "ktadd -k /keytabs/zoo.keytab zookeeper/zoo2.$DOMAIN@$REALM"
kadmin.local -q "ktadd -k /keytabs/zoo.keytab zookeeper/zoo3.$DOMAIN@$REALM"

echo "Adding connect{1..3} principal + datagen/jdbcsink to connect.keytab"
kadmin.local -q "ktadd -k /keytabs/connect.keytab connect1@$REALM"
kadmin.local -q "ktadd -k /keytabs/connect.keytab connect2@$REALM"
kadmin.local -q "ktadd -k /keytabs/connect.keytab connect3@$REALM"
kadmin.local -q "ktadd -k /keytabs/connect.keytab datagen@$REALM"
kadmin.local -q "ktadd -k /keytabs/connect.keytab jdbcsink@$REALM"

echo "Creating c3.keytab"
kadmin.local -q "ktadd -k /keytabs/c3.keytab c3@$REALM"

echo "Adding schema{1..3} to schema.keytab"
kadmin.local -q "ktadd -k /keytabs/schema.keytab schema1@$REALM"
kadmin.local -q "ktadd -k /keytabs/schema.keytab schema2@$REALM"
kadmin.local -q "ktadd -k /keytabs/schema.keytab schema3@$REALM"

echo "Creating ksql.keytab"
kadmin.local -q "ktadd -k /keytabs/ksql.keytab ksql1@$REALM"

echo "Creating admin.keytab"
kadmin.local -q "ktadd -k /keytabs/admin.keytab admin@$REALM"

echo "Creating client.keytab"
kadmin.local -q "ktadd -k /keytabs/client.keytab client@$REALM"

echo "Updating permissions on keytab files to ensure readable inside Kafka containers"
# Default perm is 600
chmod 644 /keytabs/*.keytab
echo "Available Keytabs"
ls -ltr /keytabs

# create a file to signify all principals/keytabs are created
touch /tmp/initialized

krb5kdc
kadmind -nofork
