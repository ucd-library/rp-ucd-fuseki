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


# Since these are affected by configuration parameters, redo on every startup
for f in $(cd $FUSEKI_HOME; find . -name \*.tmpl); do
  n=$(dirname $f)/$(basename $f .tmpl)
  mkdir -p $(dirname ${FUSEKI_BASE}/$n)
  expandVarsStrict < ${FUSEKI_HOME}/$f > ${FUSEKI_BASE}/$n

  if [[ "$(basename $n)" = "shiro.ini" && -z "$FUSEKI_PASSWORD" ]]; then
    grep 'admin=' ${FUSEKI_BASE}/$n;
  fi
done

# Copy extra jarfiles used by fuseki.  Do this on every startup
cp -r $FUSEKI_HOME/extra $FUSEKI_BASE

if [[ -z "$FUSEKI_HARVESTDB_ENABLED" ]]; then
  export FUSEKI_HARVESTDB_ENABLED="true"
fi

if [[ -z "$FUSEKI_HARVESTDB_AUTH" ]]; then
  export FUSEKI_HARVESTDB_AUTH="true"
fi

if [[ "$FUSEKI_HARVESTDB_AUTH" == "true" ]]; then
  basic_auth="--basic-auth admin:$FUSEKI_PASSWORD"
else
  basic_auth=''
fi

: <<< ${FUSEKI_PUBLIC_VOCABULARY:="true"}
: <<< ${FUSEKI_PUBLIC_PRIVATE:="true"}

# Install default experts data
# Server Database Configuration -- Don't overwrite

function install_db() {
  local db=$1;

  for f in configuration/${db}.ttl; do
    if [[ ! -f $FUSEKI_BASE/$f ]] ; then
      mkdir -p $(dirname ${FUSEKI_BASE}/$f)
      cp ${FUSEKI_HOME}/$f ${FUSEKI_BASE}/$f
    fi
  done

  if [[ ! -d $FUSEKI_BASE/databases/${db}/ ]]; then
    local dir=$FUSEKI_HOME/${db};
    # triples (no graph)
    for fn in $(find ${dir} -maxdepth 1 -name \*.ttl -o -name \*.ttl.gz); do
        tdb2.tdbloader --tdb=$FUSEKI_BASE/configuration/${db}.ttl $fn
    done
    # Now named graphs
    for fn in $(find ${dir}/*/* -type f -name \*.ttl -o -name \*.ttl.gz ); do
        graph=$(basename $(dirname $fn))
        tdb2.tdbloader --tdb=$FUSEKI_BASE/configuration/${db}.ttl --graph="$(printf 'http://%b/' ${graph//%/\\x})" $fn
    done
  fi
}

# Always install experts
install_db experts

if [[ $FUSEKI_PUBLIC_PRIVATE == "true" ]]; then
  install_db private
else
  rm -f $FUSEKI_BASE/configuration/private.ttl
#  rm -r -f $FUSEKI_BASE/databases/private
fi

if [[ $FUSEKI_PUBLIC_VOCABULARY == "true" ]]; then
  install_db vocabularies
else
  rm -f $FUSEKI_BASE/configuration/vocabularies.ttl
fi


# Startup our https://github.com/msoap/shell2http
if [[ "$FUSEKI_HARVESTDB_ENABLED" == "true" ]]; then
  echo   "shell2http --form [[--auth]] --export-vars FUSEKI_PASSWORD POST:/harvestdb 'fuseki-harvestdb --name=$v_name new' DELETE:/harvestdb 'fuseki-harvestdb --name=$v_name rm' GET:/harvestdb 'fuseki-harvestdb list'"
  shell2http --form ${basic_auth}  --export-vars FUSEKI_PASSWORD POST:/harvestdb 'fuseki-harvestdb --name=$v_name new' DELETE:/harvestdb 'fuseki-harvestdb --name=$v_name rm' GET:/harvestdb 'fuseki-harvestdb list' &
fi


if [[ $KAFKA_ENABLED == "true" ]]; then
  echo "waiting for kafka: ${KAFKA_HOST}:${KAFKA_PORT}"
  wait-for-it -t 0 ${KAFKA_HOST}:${KAFKA_PORT}
fi
# Run the CMD
exec "$@"
