%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT snortconfig 'lib/snort/etc/snort.conf'
%DEFAULT cvss 'data/snort-cvss.tsv'

-- CVSS data
cvss = LOAD '$cvss' AS (sig:chararray, severity:float);

-- Snort
snort_alerts_real = LOAD '$pcap'
  USING com.blackfoundry.pig.loaders.pcap.detection.SnortLoader('$snortconfig')
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

snort_alerts_test = LOAD 'data/snort_alerts_test_data.tsv'
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

-- Generate Country
snort_alerts = FOREACH snort_alerts_real
  GENERATE
    sig,
    priority,
    ts / $time * $time as ts,
    com.blackfoundry.pig.udf.geoip.Country(src) as country;

-- Join Snort with CVSS
snort_alerts = JOIN
  snort_alerts BY sig LEFT OUTER,
  cvss BY sig;

------------------------------------------------------------------------------
-- Country Attack Types - Group by snort sig, country, timestamp
------------------------------------------------------------------------------

country_attack_types = GROUP snort_alerts
  BY (snort_alerts::sig, country, ts);

-- Flatten and count
country_attack_types = FOREACH country_attack_types
  GENERATE
    FLATTEN(group),
    COUNT(snort_alerts.ts);

dump country_attack_types;

-- Output
STORE snort_alerts INTO 'output/country_attack_types_graph' USING PigStorage(',');

