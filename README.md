## Linkedin_cc

## Linkedin Cruise Control docker image

## Pull image:
    docker pull 11nehas/cruise-control:latest

## Run container:
    docker run -p 9091:9091 -v $PWD/config/cruisecontrol.properties:/cc/config/cruisecontrol.properties -v $PWD/config/capacityCores.json:/cc/config/capacityCores.json 11nehas/cruise-control:latest

## Config files:
    We use 2 manditory configfiles cruisecontrol.properties and capacityCores.json which should be 
    provided by the user.

    # cruisecontrol.properties <Manadatory parameters>
    | Name | Description | Default | Required |
    |------|-------------|---------|:--------:|
    |bootstrap.servers| Kafka bootstrap endpoint | localhost:9092 | yes|
    |sasl.jaas.config | Need sasl jaas config url with username and password if sasl authentication is enabled in kafka | | optional if SASL/SCRAM is enable in Kafka |
    |metric.sampler.class | Configurations for the load monitor metric sampler class |com.linkedin.kafka.cruisecontrol.monitor.sampling.CruiseControlMetricsReporterSampler| yes|
    | prometheus.server.endpoint | If prometheus metric sampler class is selected | | option |  
    |zookeeper.connect| Zooker end point| localhost:2181| yes|

## Features:
    --------------------------------------------------
    |Cruise-control with SASL/SCRAM authententication |
    --------------------------------------------------
    cruisecontrol.properties option to be used:
    |security.protocol=SASL_SSL|
    |sasl.mechanism=SCRAM-SHA-512|
    |sasl.jaas.config= org.apache.kafka.common.security.scram.ScramLoginModule  required \ username='' \ password='';| 

    ---------------------------------------------------------
    | Cruise-control with metric sampler class as Prometheus|
    ---------------------------------------------------------
    For using prometheus as metric sampler class cruisecontrol.properties option to be used:
    
    |metric.sampler.class=com.linkedin.kafka.cruisecontrol.monitor.sampling.prometheus.PrometheusMetricSampler|
    |prometheus.server.endpoint=<prometheus_end_point>|

## web ui config location
    webserver.ui.diskpath=./cruise-control-ui
    
    Add a /cruise-control-ui/ui-config.csv if you want to adjust web ui config.