#!/bin/sh


CONTEXT_SUFFIX=`echo $1 | sed 's/\%2F/_/g'`
WORKSPACE_PATH="$2/fileStore"
PATH_TO_SRC_ROOT=$3

MONGO_DB_CONTAINER_NAME="mongodb_$CONTEXT_SUFFIX"
MONGO_DB_USER="root"
MONGO_DB_PASSWORD="autotestPassword"
MYSQL_DB_CONTAINER_NAME="mysql_$CONTEXT_SUFFIX"
MYSQL_DB_USER="root"
MYSQL_DB_PASSWORD="autotestPassword"
RABBIT_MQ_CONTAINER_NAME="rabbitmq_$CONTEXT_SUFFIX"
INFLUX_DB_CONTAINER_NAME="influxdb_$CONTEXT_SUFFIX"

function printHeader() {
	echo ""
	echo "# ##############################################################################"
	echo "#  $1"
	echo "# ##############################################################################"
}

function annotateOutput() {
	while read line
	do
		echo " - [$1]: $line"
	done
}

function getFreeRandomPort() {
    python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()'
}

printHeader "Starting itinialization of sdCloud test environment"

if [ -f docker-compose.yml ]; then
    echo " - Found docker-compose.yml. Removing it"
    rm "docker-compose.yml"
    echo ""
fi

echo " - Creating docker-compose.yml from template"
cp docker-compose.template.yml docker-compose.yml
echo ""

echo " - Generating porst to be used.."
MONGO_DB_PORT=`getFreeRandomPort`
MYSQL_DB_PORT=`getFreeRandomPort`
SERVER_WEB_PORT=`getFreeRandomPort`
SERVER_WEB_API_PORT=`getFreeRandomPort`
RABBIT_MQ_D_PORT=`getFreeRandomPort`
RABBIT_MQ_M_PORT=`getFreeRandomPort`
INFLUX_DB_PORT=`getFreeRandomPort`
echo " - - Got following ports:"
echo " - - - MONGO_DB_PORT:       $MONGO_DB_PORT"
echo " - - - MYSQL_PORT:          $MYSQL_PORT"
echo " - - - SERVER_WEB_PORT:     $SERVER_WEB_PORT"
echo " - - - RABBIT_MQ_D_PORT:    $RABBIT_MQ_D_PORT"
echo " - - - RABBIT_MQ_M_PORT:    $RABBIT_MQ_M_PORT"
echo " - - - INFLUX_DB_PORT:      $INFLUX_DB_PORT"
echo ""

echo " - Updating docker-compose.yml"

# Setting params for MongoDB container
sed -i "s/_MONGO_DB_NAME_/$MONGO_DB_CONTAINER_NAME/g" docker-compose.yml
sed -i "s/_MONGO_DB_PORT_/$MONGO_DB_PORT/g" docker-compose.yml
sed -i "s/_MONGO_DB_USER_/$MONGO_DB_USER" docker-compose.yml
sed -i "s/_MONGO_DB_PASSWORD_/$MONGO_DB_PASSWORD" docker-compose.yml

# Setting params for MySQL/MariaDB container
sed -i "s/_MYSQL_DB_NAME_/$MYSQL_DB_CONTAINER_NAME/g" docker-compose.yml
sed -i "s/_MYSQL_DB_PORT_/$MYSQL_DB_PORT/g" docker-compose.yml
sed -i "s/_MYSQL_DB_PASSWORD_/$MYSQL_DB_PASSWORD" docker-compose.yml

# Setting params for RabbitMQ container
sed -i "s/_RABBIT_MQ_NAME_/$RABBIT_MQ_CONTAINER_NAME/g" docker-compose.yml
sed -i "s/_RABBIT_MQ_D_PORT_/$RABBIT_MQ_D_PORT/g" docker-compose.yml
sed -i "s/_RABBIT_MQ_M_PORT_/$RABBIT_MQ_M_PORT/g" docker-compose.yml

# Setting params for InfluxDB container
sed -i "s/_INFLUX_DB_NAME_/$INFLUX_DB_CONTAINER_NAME/g" docker-compose.yml
sed -i "s/_INFLUX_DB_PORT_/$INFLUX_DB_PORT/g" docker-compose.yml

echo ""

printHeader "Resulting docker-compose.yml (start)"
cat docker-compose.yml
printHeader "Resulting docker-compose.yml (end)"
echo ""

echo " - Writing generated.env properties"

echo "MONGO_DB_PORT=$MONGO_DB_PORT" > generated.env
echo "MONGO_DB_USER=$MONGO_DB_USER" > generated.env
echo "MONGO_DB_PASSWORD=$MONGO_DB_PASSWORD" > generated.env

echo "MYSQL_DB_PORT=$MYSQL_DB_PORT" >> generated.env
echo "MYSQL_DB_USER=$MYSQL_DB_USER" >> generated.env
echo "MYSQL_DB_PASSWORD=$MYSQL_DB_PASSWORD" >> generated.env

echo "SERVER_WEB_PORT=$SERVER_WEB_PORT" >> generated.env
echo "SERVER_WEB_API_PORT=$SERVER_WEB_API_PORT" >> generated.env

echo "RABBIT_MQ_D_PORT=$RABBIT_MQ_D_PORT" >> generated.env
echo "RABBIT_MQ_M_PORT=$RABBIT_MQ_M_PORT" >> generated.env

echo "INFLUX_DB_PORT=$INFLUX_DB_PORT" >> generated.env
mkdir -p "$WORKSPACE_PATH"

echo "WORKSPACE_PATH=$WORKSPACE_PATH" >> generated.env
echo ""

printHeader "Starting docker containers"
docker-compose up -d --build
echo ""

printHeader "Waiting for containers to start"
sleep 30

echo""
echo "Containers summary:"
echo "--------------------------------"
docker ps -a | grep '\'$CONTEXT_SUFFIX
echo "--------------------------------"
echo ""

echo "Polling MySQL database"
retriesLeft=25
mysql -u root -h 127.0.0.1 -P $MYSQL_PORT -pautotestPassword << EOF
    exit
EOF

while (( $? != 0 && retriesLeft >= 0))
do
    echo " - Retries left: $retriesLeft"
    sleep 10
    retriesLeft=`expr $retriesLeft - 1`
    mysql -u root -h 127.0.0.1 -P $MYSQL_PORT -pautotestPassword << EOF
        exit
EOF
done
echo ""

echo "Polling MONGO database"
retriesLeft=25
echo "new Mongo(\"localhost:$MONGO_DB_PORT\")" > mongotest.js
mongo --port $MONGO_DB_PORT mongotest.js

while (( $? != 0 && retriesLeft >= 0))
do
    echo " - Retries left: $retriesLeft"
    sleep 10
    retriesLeft=`expr $retriesLeft - 1`
    mongo --port $MONGO_DB_PORT mongotest.js
done
echo ""

printHeader "Setting up database schema"
echo "--- skipped ---"
# mysql -u root -h 127.0.0.1 -P $MYSQL_PORT -pautotestPassword << EOF
#     CREATE DATABASE sdcloudAutotest;
#     use sdcloudAutotest;
#     source $PATH_TO_SRC_ROOT/SQL/sdcloud-db.sql;
#     exit
# EOF
echo ""

printHeader "Insering test data"
echo "--- skipped ---"
# mysql -u root -h 127.0.0.1 -P $MYSQL_PORT -pautotestPassword << EOF
#     use sdcloudAutotest;
#     INSERT INTO user (UserName,PasswordHash,SecurityStamp,RegistrationDateUtc,LockoutEndDateUtc,LockoutEnabled,AccessFailedCount,Email,EmailConfirmed,PhoneNumber,PhoneNumberConfirmed,TwoFactorEnabled,Organisation,OrganisationRole) VALUES ('testUser','ALBTelDNjZlUwYuw/edZilNUD6qv2PFx4L5VAUuh5qAezedQ/l7bMN2+X1AYDmthuQ==','9f9cf974-1f05-4fd6-8ebf-b674d0afac47','2019-01-13 07:24:11',NULL,0,0,'testUser@sdcloud.io',0,NULL,0,0,NULL,NULL);
# EOF
echo ""