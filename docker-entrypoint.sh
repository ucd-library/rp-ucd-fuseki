#! /bin/bash

if [ -f "/fuseki/databases/vivo/tdb.lock" ] ; then
  echo "WARNING: fuseki lock file found.  removing."
  rm /fuseki/databases/vivo/tdb.lock
fi 
if [ -f "/fuseki/system/tdb.lock" ] ; then
  echo "WARNING: fuseki lock file found.  removing."
  rm /fuseki/system/tdb.lock
fi 

if [[ -z "$KAFKA_ENABLED" ]]; then
  export KAFKA_ENABLED=true
fi
if [[ -z "$KAFKA_HOST" ]]; then
  export KAFKA_HOST=kafka
fi
if [[ -z "$KAFKA_PORT" ]]; then
  export KAFKA_PORT=9092
fi
if [[ -z "$KAFKA_TOPIC" ]]; then
  export KAFKA_TOPIC=fuseki-rdf-patch
fi

if [[ -z "$KAFKA_USERNAME" ]]; then
  export KAFKA_USERNAME=""
else
  KAFKA_USERNAME="ucd:kafkaUsername \"${KAFKA_USERNAME}\" ;"
fi

if [[ -z "$KAFKA_PASSWORD" ]]; then
  export KAFKA_PASSWORD=""
else
  KAFKA_PASSWORD="ucd:kafkaPassword \"${KAFKA_PASSWORD}\" ;"
fi

for f in $FUSEKI_BASE/*.tpl; do

  content=$(cat $f)
  for var in $(compgen -e); do
    content=$(echo "$content" | sed "s|{{$var}}|${!var}|g")
  done
  f=$(echo ${f%.*})
  echo "$content" > $f
done

if [[ $KAFKA_ENABLED == "true" ]]; then
  echo "waiting for kafka: ${KAFKA_HOST}:${KAFKA_PORT}"
  wait-for-it -t 0 ${KAFKA_HOST}:${KAFKA_PORT}
fi

exec /docker-entrypoint-org.sh "$@"