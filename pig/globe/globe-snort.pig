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

latlon = FOREACH snort_alerts
  GENERATE ts,
    com.packetloop.packetpig.udf.geoip.LatLon(src) as ll,
    priority;

latlon = GROUP latlon
  BY ll;

latlon = FOREACH latlon
  GENERATE
    group,
    AVG(latlon.priority) as average_severity,
    COUNT(latlon.priority) as total_attacks;

latlon = ORDER latlon BY total_attacks;

STORE latlon into 'output/globe_snort' using PigStorage(',');

