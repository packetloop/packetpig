%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT snortconfig 'lib/snort/etc/snort.conf'

snort_alerts = LOAD '$pcap'
  USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('$snortconfig')
  AS (
    ts:long,
    sig:chararray,
    priority:int,
    message:chararray,
    proto:chararray,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int
  );

countries = FOREACH snort_alerts
  GENERATE
    com.packetloop.packetpig.udf.geoip.Country(src) as country,
    priority;

countries = GROUP countries
  BY country;

countries = FOREACH countries
  GENERATE
    group,
    AVG(countries.priority) as average_severity;

STORE countries into 'output/choropleth_countries' using PigStorage(',');

