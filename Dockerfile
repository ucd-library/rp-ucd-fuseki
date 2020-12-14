FROM ucdlib/jena-fuseki-eb:jena-3.15.0

RUN set -eux && \
    apt-get update && \
    apt-get install -y util-linux rsync perl wait-for-it git && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p $FUSEKI_HOME/extra
COPY ./lib/jena-kafka-connector-0.0.3-SNAPSHOT.jar ./lib/kafka-clients-2.5.0.jar $FUSEKI_HOME/extra/

COPY ./jetty-config.xml $FUSEKI_HOME/
COPY ./config.ttl.tmpl $FUSEKI_HOME/
COPY ./tdb.cfg.tmpl $FUSEKI_HOME/
COPY ./shiro.ini.tmpl $FUSEKI_HOME/
COPY ./configuration $FUSEKI_HOME/configuration/
COPY ./databases $FUSEKI_HOME/databases/
COPY ./rp-ucd-fuseki-docker-entrypoint.sh /rp-ucd-fuseki-docker-entrypoint.sh
COPY ./fuseki-import-graphs /usr/local/bin

ENTRYPOINT ["/rp-ucd-fuseki-docker-entrypoint.sh"]

CMD ["/jena-fuseki/fuseki-server", "--jetty-config=/jena-fuseki/jetty-config.xml"]
