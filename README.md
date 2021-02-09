# rp-ucd-fuseki
UC Davis Library RP Fuseki instance with the fuseki-kafka-connector

# Env Params

## fuseki

The following parameters (and their defaults) affect the actual instance:

- `${FUSEKI_PASSWORD:-$(pwgen -s 15)}` - Fuseki ADMIN password, if not set will
  echo the password to the log file
- `${FUSEKI_TIMEOUT_FIRST:-30000}` - Fuseki timeout on queries for first response
- `${FUSEKI_TIMEOUT_REST:-120000}` - Fuseki timeout on queries for all responses

The following parameters (set in .env) are common parameters used in the
docker-compose initialization file:

- `${FUSEKI_VERSION:-1.1.3}` - fuseki version to use
- `${FUSEKI_PORT:-3004}` - External Port assignment


## Kafka

Defaults shown

- `${KAFKA_ENABLED:-TRUE}` = Set to false to disable kafka
- `${KAFKA_TOPIC:-fuseki-rdf-patch}`
- `${KAFKA_HOST:-kafka}`
- `${KAFKA_PORT:-3030}`
- `${KAFKA_USERNAME}`
- `${KAFKA_PASSWORD}`


# Fuseki Initialization

`rp-ucd-fuseki` sets up the default `experts` service, the only service needed
in the Aggie Experts deployment.  Even without initialization, the experts
system should at least come up, albiet with no data.

The quickest method for testing the system is to directly import public graphs
into the system.  Using fuseki's `/data` import http endpoint will also trigger
the kafka stream reader, and should automatically update the Aggie Experts
search indices as well.

There are some standard graphs that are used in the Aggie experts, `experts`
service.  The service also has a default graph, which is the union, and
typically used for queries.  The graphs really only show provenance of the data.

``` text
├── experts.ucdavis.edu
│   └── *.ttl.gz    # Constant data
├── experts.ucdavis.edu%2Foap
│   └── *.ttl.gz    # Public data from the CDL publication system.
└── experts.ucdavis.edu%2Fiam
    └── *.ttl.gz    # Public data from the UCD IAM system.

```

## Github Initialization

The container includes a script, `fuseki-import-graphs` can clone data from a
git repository, and import that data.  The data is cloned into a directory of
`/fuseki/import/` which *should* be a docker volume, and not affect the
instance.  For example, the library's gitlab instance requires a token for
access to private data.  After setting up that token, you can have the script
pull data from that repository.  You can add `--clone` flags as well. The example
below shows a typical use for this:

``` bash
docker-compose exec fuseki fuseki-import-graphs
--clone="https://quinn:${GITLAB_PUSH_TOKEN}@gitlab.dams.library.ucdavis.edu/experts/experts-data.git
--single-branch --branch=experts-2.0.0"
```

## Docker initialization via mounts

Alternatively, you can use the same `fueski-import-graphs` command in the docker
instance to import the data.  The advantage here is that the scripts should
work, it's not required to expose the fuseki port, and the required variables
will be set in the environment.  The disadvantage is that you need to make the
data available to the docker instance.  Below is an example yml file, that shows
a local mount into the container.

```yaml
version: '3.5'

services:
  fuseki:
    image: ucdlib/rp-ucd-fuseki:${FUSEKI_VERSION:-1.1.3}
#    command: tail -f /dev/null
    environment:
      - JVM_ARGS=${JVM_ARGS:- -Xmx4g}
      - FUSEKI_PASSWORD=${FUSEKI_PASSWORD:-quinnisgreat}
      - KAFKA_ENABLED=${KAFKA_ENABLED:-false}
    volumes:
      - fuseki-data:/fuseki
      - ~/experts-data/experts:/fuseki/import
    ports:
      - ${FUSEKI_HOST_PORT:-7030}:3030

volumes:
  fuseki-data:
    driver: local
```

With this setup, you can initial graphs with:

``` bash
docker-compose exec fuseki fuseki-import-graphs /fuseki/import
```

In order to utilize the KAFKA stream monitoring, `fuseki-import-graphs`
requires the fuseki server to be running.

## Local /data loads

After the system is started, if the fuseki port is exposed to your local host,
you can directly add data from outside the docker instance.  The advantage of
this is that you don't need to get the test data into your docker instance, the
disadvantage is that your mileage may vary on the import script.

``` bash
auth=admin:${FUSEKI_PASSWORD}
load=http://localhost:${FUSEKI_HOST_PORT:-3004}/experts/data
for f in $(find experts.ucdavis.edu -type f -name \*.ttl -o -name \*.ttl.gz ); do
  g=$(basename $(dirname $f))
  curl --user "${auth}" -F "file=@$f" "${load}?graph=$(printf 'http://%b/' ${g//%/\\x})"
done
```


# Fuseki Harvest ADMIN interface

The Fuseki service includes an administrative interface to create new services.
This service is similar to the [Fuseki Admin
Interface](https://jena.apache.org/documentation/fuseki2/fuseki-server-protocol.html),
but with some extensions.  First, the Fuseki Admin interface currently does not
allow custom assembler definitions.  And secondly, on deletion, the fuseki admin
interface does not remove any database data.

A second HTTP interface allows for the creation and removal of new services.
These services are designed to be used as harvest tools, and their service
definitions link to the experts public data, and create a separate private
database as well.  The service runs on port 8080, and allows three methods to
the interface.  To create a new harvest service, POST to the endpoint, for
example `curl -i --user admin:$FUSEKI_PASSWORD -X POST
http://fuseki:8080/harvestdb?name=harvest.test`.  This will return the name of
the new service.  Alternatively, you can set the name of the service as well.
`curl -i --user admin:$FUSEKI_PASSWORD -X POST
http://fuseki:8080/harvestdb?name=harvest.test`.  Use the `DELETE` method to
remove an existing harvest service. `curl -i --user admin:$FUSEKI_PASSWORD -X
DELETE http://fuseki:8080/harvestdb?name=harvest.test`.  The `GET` method will
return a list of existing harvest services.  `curl -i --user
admin:$FUSEKI_PASSWORD -X GET http://fuseki:8080/harvestdb`.

Currently, only simple text messages are returned.  Later, we will add a more
respectable JSON return.  Also note that due to limitations of the server, all
valid requests will return `202` even if the function fails.


# Test Instance

This project includes a test.yml file that can be used for testing the fuseki
installation outside of the complete rp-ucd-deployment.  This is also a good way
to setup a service if you just want to query the data.

One method to manage the test is with an alias as in:

``` bash
alias fdc="docker-compose -p fuseki-test -f $(pwd)/test.yml"
```
Then you can manage the file as in:

``` bash
fdc up -d #or
fdc exec fuseki bash
```

This compose file should have reasonable defaults, but updates to .env (eg
FUSEKI_VERSION=1.1.3) will update the startup.  An `.env` file is *NOT* required
however. The fuseki_endpoint for the default is
`http://admin:testing@fuseki:3030/` with experts and experts-dev databases.


# Special Server Initialization

By default, the server is launched like `/jena-fuseki/fuseki-server
--jetty-config=/jena-fuseki/jetty-config.xml`  You can modify this in the
docker compose command, for example to use another configuration file try:

``` yaml
   command: ["/jena-fuseki/fuseki-server", "--jetty-config=/foo/jetty-config.xml"]
```

In addition, occasionally, you may wish to start the service without starting
the fuseki server.  You may want to investigate the underlying tdb2 databases,
or the configuration files for example.  In that case you can start the service
with something like:

``` yaml
   command: tail -f /dev/null
```

Then you can execute commands (like a bash interactive script) in the server.
Not that even if you have started the server, you can always execute commands to
the instance.


# Versions

- (Version 1.2.*)[https://github.com/ucd-library/rp-ucd-fuseki/issues/11]
