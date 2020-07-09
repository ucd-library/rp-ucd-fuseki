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
  export KAFKA_PORT=3030
fi

if [[ -z "$KAFKA_TOPIC" ]]; then
  export KAFKA_TOPIC=fuseki-rdf-patch
fi
if [[ -z "$KAFKA_USERNAME" && -z "$KAFKA_PASSWORD" ]]; then
  KAFKA_TOPIC="\"$KAFKA_TOPIC\" .";
else
  KAFKA_TOPIC="\"$KAFKA_TOPIC\" ;";
fi

if [[ -z "$KAFKA_USERNAME" ]]; then
  export KAFKA_USERNAME=""
else
  KAFKA_USERNAME="ucd:kafkaUsername \"${KAFKA_USERNAME}\""
fi
if [[ ! -z "$KAFKA_PASSWORD" ]]; then
  KAFKA_USERNAME="$KAFKA_USERNAME ;"
elif [[ ! -z "$KAFKA_USERNAME" ]]; then
  KAFKA_USERNAME="$KAFKA_USERNAME ."
fi

if [[ -z "$KAFKA_PASSWORD" ]]; then
  export KAFKA_PASSWORD=""
else
  KAFKA_PASSWORD="ucd:kafkaPassword \"${KAFKA_PASSWORD}\" ."
fi

for f in $FUSEKI_BASE/*.tpl; do

  content=$(cat $f)
  for var in $(compgen -e); do
    content=$(echo "$content" | sed "s|{{$var}}|${!var}|g")
  done
  f=$(echo ${f%.*})
  echo "$content" > $f
done

exec /docker-entrypoint-org.sh "$@"