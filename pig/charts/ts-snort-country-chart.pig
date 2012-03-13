%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 86400
%DEFAULT snortconfig 'lib/snort/etc/snort.conf'

-- Snort
snort_alerts_real =
  LOAD '$pcap'
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

snort_alerts = FOREACH snort_alerts_real
  GENERATE
    sig,
    priority,
    ts / $time * $time as ts,
    com.packetloop.packetpig.udf.geoip.Country(src) as country;

snort_alerts = FILTER snort_alerts
  BY country == 'AU'
  OR country == 'CN'
  OR country == 'DE'
  OR country == 'JP'
  OR country == 'NL'
  OR country == 'KR'
  OR country == 'NZ'
  OR country == 'US';

--------------------------------------------------------------------------------
-- All alerts (Any severity)
--------------------------------------------------------------------------------

snort_all = GROUP snort_alerts
  BY (country, ts);

snort_all = FOREACH snort_all
  GENERATE
    FLATTEN(group),
    COUNT(snort_alerts.ts) as attacks;

snort_all = FOREACH snort_all
  GENERATE
    'All Severities', country, ts, attacks;

STORE snort_all INTO 'output/ts-chart/1-all' USING PigStorage(',');

