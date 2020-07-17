FROM ucdlib/jena-fuseki-eb:jena-3.15.0

RUN set -eux && \
    apt-get update && \
    apt-get install -y util-linux rsync perl wait-for-it && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p $FUSEKI_HOME/extra
COPY ./lib/jena-kafka-connector-0.0.3-SNAPSHOT.jar ./lib/kafka-clients-2.5.0.jar $FUSEKI_HOME/extra/

COPY ./jetty-config.xml $FUSEKI_HOME
COPY ./config.ttl.tpl $FUSEKI_HOME/

# fuseki-db-init is our local bash script to initialize databases
COPY ./fuseki-db-init /usr/local/bin/fuseki-db-init
RUN chmod 755 /usr/local/bin/fuseki-db-init

# By default show the initialization
ENV FUSEKI_DB_INIT_ARGS=--verbose
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/jena-fuseki/fuseki-server", "--jetty-config=/jena-fuseki/jetty-config.xml"]
