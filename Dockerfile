FROM ucdlib/jena-fuseki-eb:jena-3.15.0

RUN set -eux && \
    apt-get update && \
    apt-get install -y util-linux rsync perl wait-for-it && \
    rm -rf /var/lib/apt/lists/*


RUN mkdir -p $FUSEKI_HOME/extra
COPY ./lib/jena-kafka-connector-0.0.3-SNAPSHOT.jar $FUSEKI_HOME/extra/
COPY ./lib/kafka-clients-2.5.0.jar $FUSEKI_HOME/extra/
COPY ./jetty.xml /$FUSEKI_HOME
COPY ./config.ttl.tpl $FUSEKI_HOME/
COPY ./fz /usr/local/bin/fz
RUN chmod 755 /usr/local/bin/fz

#RUN mv /docker-entrypoint.sh /docker-entrypoint-org.sh
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/jena-fuseki/fuseki-server"]
#CMD ["/jena-fuseki/fuseki-server","--jetty-config=/fuseki/jetty.xml"]
