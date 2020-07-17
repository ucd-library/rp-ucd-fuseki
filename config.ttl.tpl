# Licensed under the terms of http://www.apache.org/licenses/LICENSE-2.0

## Fuseki Server configuration file.

@prefix :        <#> .
@prefix fuseki:  <http://jena.apache.org/fuseki#> .
@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix ja:      <http://jena.hpl.hp.com/2005/11/Assembler#> .
@prefix ucd:     <http://library.ucdavis.edu/ns#> .

[] rdf:type fuseki:Server ;
   # Example::
   # Server-wide query timeout.
   #
   # Timeout - server-wide default: milliseconds.
   # Format 1: "1000" -- 1 second timeout
   # Format 2: "10000,60000" -- 10s timeout to first result,
   #                            then 60s timeout for the rest of query.
   #
   # See javadoc for ARQ.queryTimeout for details.
   # This can also be set on a per dataset basis in the dataset assembler.
   #
   ja:context [ ja:cxtName "arq:queryTimeout" ;  ja:cxtValue "5000,60000" ] ;

   # Add any custom classes you want to load.
   # Must have a "public static void init()" method.
   ja:loadClass "edu.ucdavis.library.FusekiKafkaConnector"

   # End triples.
   .

[] rdf:type ucd:Kafka ;
  ucd:kafkaEnabled "{{KAFKA_ENABLED}}" ;
  {{KAFKA_USERNAME}}
  {{KAFKA_PASSWORD}}
  ucd:kafkaTopic "{{KAFKA_TOPIC}}" ;
  ucd:kafkaHost "{{KAFKA_HOST}}" ;
  ucd:kafkaPort "{{KAFKA_PORT}}"
  .
