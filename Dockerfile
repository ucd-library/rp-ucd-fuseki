FROM ucdlib/jena-fuseki-eb:jena-3.15.0

RUN mv /docker-entrypoint.sh /docker-entrypoint-org.sh
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p $FUSEKI_BASE/extra
COPY ./lib/jena-kafka-connector-0.0.2-SNAPSHOT.jar $FUSEKI_BASE/extra/
COPY ./lib/kafka-clients-2.5.0.jar $FUSEKI_BASE/extra/
COPY ./config.ttl.tpl $FUSEKI_BASE/

CMD ["/docker-entrypoint.sh", "/jena-fuseki/fuseki-server"]