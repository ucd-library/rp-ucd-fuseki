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

# Server Configuration -- Don't overwrite
for f in $(cd $FUSEKI_HOME; find databases -type f); do
  n=$(dirname $f)/$(basename $f .tmpl)
  if [[ ! -f $FUSEKI_BASE/$n ]] ; then
    mkdir -p $(dirname ${FUSEKI_BASE}/$n)
    cp ${FUSEKI_HOME}/$f ${FUSEKI_BASE}/$n
  fi
done

for f in $(cd $FUSEKI_HOME; find . -name \*.tmpl); do
  n=$(dirname $f)/$(basename $f .tmpl)
  if [[ ! -f $FUSEKI_BASE/$n ]] ; then
    mkdir -p $(dirname ${FUSEKI_BASE}/$n)
    expandVarsStrict < ${FUSEKI_HOME}/$f > ${FUSEKI_BASE}/$n
  fi
  if [[ "$(basename $n)" = "shiro.ini" && -z "$ADMIN_PASSWORD" ]]; then
    grep 'admin=' ${FUSEKI_BASE}/$n;
  fi
done

function experts_preload() {
  for loc in public private; do
    if [[ -d /experts-preload/$loc ]]; then
      for d in $(find /experts-preload/$loc -mindepth 1 -type d); do
        graph="http://$(urldecode $(basename $d))/"
        for f in $(find $d -type f -name \*.ttl -o -name \*.ttl.gz -o -name \*.n3 -o -name \*.n3.gz ); do
          tdb2.tdbloader --graph="$graph" --loader=parallel --loc=${FUSEKI_BASE}/databases/experts/$loc $f
        done
      done
    fi
  done
}

if [[ $KAFKA_ENABLED == "true" ]]; then
  echo "waiting for kafka: ${KAFKA_HOST}:${KAFKA_PORT}"
  wait-for-it -t 0 ${KAFKA_HOST}:${KAFKA_PORT}
fi
# Run the CMD
exec "$@"
