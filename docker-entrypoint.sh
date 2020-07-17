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

# Server Conifiguration
for f in $FUSEKI_HOME/*.tpl; do
  content=$(cat $f)
  for var in $(compgen -e); do
    content=$(echo "$content" | sed "s|{{$var}}|${!var}|g")
  done
  f=$FUSEKI_BASE/$(basename $f .tpl)
  echo "$content" > $f
done

#
# Now let's initial our Fuseki databases
#
set -e

# We need to verify that any extra jars are in the base.
# Even if the FUSEKI_BASE is a volume
cp -a $FUSEKI_HOME/extra $FUSEKI_BASE

# This allows for local adjustments to the jetty-configuration
if [ ! -f "$FUSEKI_BASE/jetty-config.xml" ]; then
  cp "$FUSEKI_HOME/jetty-config.xml" $FUSEKI_BASE
fi

# Update the shiro.ini on initialaation only
if [ ! -f "$FUSEKI_BASE/shiro.ini" ] ; then
  # First time
  echo "###################################"
  echo "Initializing Apache Jena Fuseki"
  echo ""
  cp "$FUSEKI_HOME/shiro.ini" "$FUSEKI_BASE/shiro.ini"
  if [ -z "$ADMIN_PASSWORD" ] ; then
    ADMIN_PASSWORD=$(pwgen -s 15)
    echo "Randomly generated admin password:"
    echo ""
    echo "admin=$ADMIN_PASSWORD"
  fi
  echo ""
  echo "###################################"
fi

# However, $ADMIN_PASSWORD can always override
if [ -n "$ADMIN_PASSWORD" ] ; then
  sed -i "s/^admin=.*/admin=$ADMIN_PASSWORD/" "$FUSEKI_BASE/shiro.ini"
fi

# If we have specified any Databases to initialize, then do that here.
[[ -n ${FUSEKI_DB_INIT} ]] && fuseki-db-init ${FUSEKI_DB_INIT_ARGS} db ${FUSEKI_DB_INIT}

if [[ $KAFKA_ENABLED == "true" ]]; then
  echo "waiting for kafka: ${KAFKA_HOST}:${KAFKA_PORT}"
  wait-for-it -t 0 ${KAFKA_HOST}:${KAFKA_PORT}
fi
# Run the CMD
exec "$@"
