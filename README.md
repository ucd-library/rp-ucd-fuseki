# rp-ucd-fuseki
UC Davis Library RP Fuseki instance with the fuseki-kafka-connector

# Env Params

## Kafka

Defaults shown

  - KAFKA_ENABLED=true
    - Set to false to disable kafka connection
  - KAFKA_HOST=kafka
  - KAFKA_PORT=3030
  - KAFKA_TOPIC=fuseki-rdf-patch
  - KAFKA_USERNAME
  - KAFKA_PASSWORD

## Fuseki

  - ADMIN_PASSWORD
    - random admin password set in not provided, see console on startup

  - FUSEKI_DB_INIT
    - This is a spaced separated list of databases to
      initialize.  See initialization, below

  - FUSEKI_DB_INIT_ARGS
    - Arguments to pass to fuseki_db_init on initialization.


# Fuseki Initialization

## fuseki_db_init

This docker file includes the tdb2.tdbloader and tdb2.tdbupdate commands
for initializing databases.  Also included is a script file
`fuseki_db_init` that is use primarily on the startup, but can also be
used interactively in the docker command.  A typical methodology would be
to mount directory to this docker container for initialization.

``` yaml
services:
  fuseki:
    image: ucdlib/rp-ucd-fuseki:${FUSEKI_VERSION:-latest}
    environment:
      - FUSEKI_DB_INIT=/staging/material_science /staging/matsci_vivo.tgz
      - FUSEKI_DB_INIT_ARGS=-v
    volumes:
      - fuseki-data:/fuseki
      - ./research-profiles/examples:/staging
    ports:
      - ${FUSEKI_EXTERNAL_PORT:-3030}:3030
```

In the example above, the /staging directory includes a mount point, and
then the `FUSEKI_DB_INIT` environment variable specifies some databases to
initialize.  This is a spaced separated list. Compressed tar files will
have the *configuration* and *databases* directories directly untarred into
the $FUSEKI_BASE.  By default, the tar command will not overwrite newer
files.  This can be modified by using `FUSEKI_DB_INIT_ARGS=--overwrite`.
URLS can also be included, and they are expected to point to compressed tar
files as well. Remember, any URLS in `FUSEKI_DB_INIT` will be fetched on
container startup, and that can take a long time for big URLS.  In that
case it may be better to cache locally.

If `FUSEKI_DB_INIT` points to a directory, then first the *configuration*
and *databases* directories will be synced to `$FUSEKI_BASE`, then graphs
in the *graph* directory will be added using `tdb2.tdbloader`.  The
directory name is the graph, (with `http://` added as a prefix and `/`
added as a suffix.  Other characters can be urlencoded in the directory
name, and will be decoded on insertion) and any `.n3` or `.ttl` files will
be loaded into that graph.  The first configuration file is used as the
assembler file for the loader.  Next, any files with extension
`sparql-update` will be used to update the database, using `tdb2.tdbupdate`.

An example directory tree is shown below:

``` text
├── configuration
│   └── material_science.ttl
├── databases
│   └── material_science
│       └── vivo.owl
├── graph
│   ├── can_insert_data_with_update_too.sparql-update
│   ├── iam.ucdavis.edu
│   │   └── experts.ttl
│   └── oapolicy.universityofcalifornia.edu
│       └── additions.n3
└── vivo.sparql-update
```

If you want to use `fuseki_db_init` more interactively, you can, for
example execute a bash shell for the container.

``` bash
docker-compose exec fuseki bash
```
There are more commands in `fuseki_db_init` try `--help` for more information.

## Server initialization.

By default, the server is launched like `/jena-fuseki/fuseki-server
--jetty-config=/jena-fuseki/jetty-config.xml`  You can modify this in the
docker compose command, for example to use another configuration file try:

``` yaml
   command: ["/jena-fuseki/fuseki-server", "--jetty-config=/foo/jetty-config.xml"]
```
