#! /bin/bash

#https://stackoverflow.com/questions/415677/how-to-replace-placeholders-in-a-text-file
function expandVarsStrict(){
  local line lineEscaped
  while IFS= read -r line || [[ -n $line ]]; do  # the `||` clause ensures that the last line is read even if it doesn't end with \n
    # Escape ALL chars. that could trigger an expansion..
    IFS= read -r -d '' lineEscaped < <(printf %s "$line" | tr '`([$' '\1\2\3\4')
    # ... then selectively reenable ${ references
    lineEscaped=${lineEscaped//$'\4'\{/\$\{}
    # Finally, escape embedded double quotes to preserve them.
    lineEscaped=${lineEscaped//\"/\\\"}
    eval "printf '%s\n' \"$lineEscaped\"" | tr '\1\2\3\4' '`([$'
  done
}

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

# Used to use ADMIN_PASSWORD
: <<< ${FUSEKI_PASSWORD:=$ADMIN_PASSWORD}

# Server Configuration -- Don't overwrite
for f in $(cd $FUSEKI_HOME; find databases -type f); do
  n=$(dirname $f)/$(basename $f .tmpl)
  if [[ ! -f $FUSEKI_BASE/$n ]] ; then
    mkdir -p $(dirname ${FUSEKI_BASE}/$n)
    cp ${FUSEKI_HOME}/$f ${FUSEKI_BASE}/$n
  fi
done

# Since these are affected by configuration parameters, redo on every startup
for f in $(cd $FUSEKI_HOME; find . -name \*.tmpl); do
  n=$(dirname $f)/$(basename $f .tmpl)
  mkdir -p $(dirname ${FUSEKI_BASE}/$n)
  expandVarsStrict < ${FUSEKI_HOME}/$f > ${FUSEKI_BASE}/$n

  if [[ "$(basename $n)" = "shiro.ini" && -z "$FUSEKI_PASSWORD" ]]; then
    grep 'admin=' ${FUSEKI_BASE}/$n;
  fi
done

if [[ $KAFKA_ENABLED == "true" ]]; then
  echo "waiting for kafka: ${KAFKA_HOST}:${KAFKA_PORT}"
  wait-for-it -t 0 ${KAFKA_HOST}:${KAFKA_PORT}
fi
# Run the CMD
exec "$@"
