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
  - FUSEKI_DATASET_*=[dataset name]
    - automatically setup dataset(s) on startup