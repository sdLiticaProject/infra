#!/bin/sh

CONTEXT_SUFFIX=`echo $1 | sed 's/\%2F/_/g'`

MONGO_DB_CONTAINER_NAME="mongodb_$CONTEXT_SUFFIX"
MYSQL_DB_CONTAINER_NAME="mysql_$CONTEXT_SUFFIX"
RABBIT_MQ_CONTAINER_NAME="rabbitmq_$CONTEXT_SUFFIX"
INFLUX_DB_CONTAINER_NAME="influxdb_$CONTEXT_SUFFIX"

docker kill $MONGO_DB_CONTAINER_NAME
docker kill $MYSQL_DB_CONTAINER_NAME
docker kill $RABBIT_MQ_CONTAINER_NAME
docker kill $INFLUX_DB_CONTAINER_NAME

docker container rm $MONGO_DB_CONTAINER_NAME
docker container rm $MYSQL_DB_CONTAINER_NAME
docker container rm $RABBIT_MQ_CONTAINER_NAME
docker container rm $INFLUX_DB_CONTAINER_NAME