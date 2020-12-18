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

- `${FUSEKI_VERSION:-1.1.0}` - fuseki version to use
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

By default, `rp-ucd-fuseki` sets up a public and private set of databases.  The
public database default `experts` is the only database that is needed in the
Aggie Experts deployment.  Even without initialization, the experts system
should at least come up, albiet with no data.

The quickest method for testing the system is to directly import public graphs
into the system.  Using fuseki's `/data` import http endpoint will also trigger
the kafka stream reader, and should automatically update the Aggie Experts
search indices as well.

There are some standard graphs that are used in the Aggie experts.
`iam.ucdavis.edu` and `oapolicy.universityofcalifornia.edu` are public graphs,
the others are private.

``` text
├── iam.ucdavis.edu
│   └── *.ttl.gz    # These data are VIVO contructed IAM data
├── oapolicy.universityofcalifornia.edu
│   └── *.ttl.gz    # These data are VIVO constructed publication data
│       └── vivo.owl
├── experts.ucdavis.edu
│   └── *.ttl.gz    # This goes to the default public database.
├── experts.ucdavis.edu%2Foap
│   └── *.ttl.gz    # Private data from the CDL publication system.
└── experts.ucdavis.edu%2Fiam
    └── *.ttl.gz    # Private data from the UCD IAM system.

```

## Local initialization

After the system is started, if the fuseki port is exposed to your local host,
you can directly add data from outside the docker instance.  The advantage of
this is that you don't need to get the test data into your docker instance, the
disadvantage is that your mileage may vary on the import script.

The preferred way to load data is via the data url for the `experts-private`
database.  Adding to this database will also add to the public `experts` database.


``` bash
auth=admin:${FUSEKI_PASSWORD}
load=http://localhost:${FUSEKI_HOST_PORT:-3004}/experts_private/data
for f in $(find iam.ucdavis.edu oapolicy.universityofcalifornia.edu -type f -name \*.ttl -o -name \*.ttl.gz ); do
  g=$(basename $(dirname $f))
  curl --user "${auth}" -F "file=@$f" "${load}?graph=$(printf 'http://%b/' ${g//%/\\x})"
done
```

## Docker initialization

Alternatively, you can use a script in the docker instance to import the data.
The advantage here is that the scripts should work, it's not required to expose
the fuseki port, and the required variables will be set in the environment.  The
disadvantage is that you need to make the data available to the docker
instance.  Below is an example yml file, that shows a local mount into the container.

```yaml
version: '3.5'

services:
  fuseki:
    image: ucdlib/rp-ucd-fuseki:${FUSEKI_VERSION:-1.1.0}
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

By default `fuseki-import-graphs` only imports public graphs, however using the
`--private` flag will import private graphs as well.  This can help decode
existing conversions from private to public data.

## Github Initialization

Finally, `fuseki-import-graphs` can also clone data from a git repository.  The
data is cloned into a directory of `/fuseki/import/` which *should* be a docker
volume, and not affect the instance.  For example, the library's gitlab instance
requires a token for access to private data.  After setting up that token, you
can have the script pull data from that repository.  You can add clone flags as
well. The example below shows a typical use for this:

``` bash
docker-compose exec fuseki fuseki-import-graphs --clone="https://quinn:${GITLAB_PUSH_TOKEN}@gitlab.dams.library.ucdavis.edu/experts/experts-data.git --single-branch --branch=experts"
```

By default `fuseki-import-graphs` only imports public graphs, however using the
`--private` flag will import private graphs as well.  This can help decode
existing conversions from private to public data.

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
FUSEKI_VERSION=1.1.1) will update the startup.  An `.env` file is *NOT* required
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
