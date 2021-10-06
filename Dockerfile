FROM gcr.io/ucdlib-pubreg/jena-fuseki-eb:jena-3.17.0

RUN set -eux && \
    apt-get update && \
    apt-get install -y util-linux rsync perl wait-for-it git git-lfs && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p $FUSEKI_HOME/extra
COPY ./lib/jena-kafka-connector-0.1.0.jar ./lib/kafka-clients-2.5.0.jar $FUSEKI_HOME/extra/

COPY --from=msoap/shell2http:latest /app/shell2http /usr/local/bin/shell2http

COPY ./jetty-config.xml $FUSEKI_HOME/
COPY ./config.ttl.tmpl $FUSEKI_HOME/
COPY ./tdb.cfg.tmpl $FUSEKI_HOME/
COPY ./shiro.ini.tmpl $FUSEKI_HOME/
COPY ./configuration $FUSEKI_HOME/configuration/
COPY ./databases $FUSEKI_HOME/databases/
COPY ./experts $FUSEKI_HOME/experts/
COPY ./vocabularies $FUSEKI_HOME/vocabularies/
COPY ./private $FUSEKI_HOME/private/
COPY ./rp-ucd-fuseki-docker-entrypoint.sh /rp-ucd-fuseki-docker-entrypoint.sh
COPY ./fuseki-import-graphs /usr/local/bin
COPY ./fuseki-harvestdb /usr/local/bin

ENTRYPOINT ["/rp-ucd-fuseki-docker-entrypoint.sh"]

CMD ["/jena-fuseki/fuseki-server", "--jetty-config=/jena-fuseki/jetty-config.xml"]
