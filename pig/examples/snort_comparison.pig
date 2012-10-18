%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60

snort_2905_alerts = 
  LOAD '$pcap'
  USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('/mnt/var/lib/snort-2905/etc/snort.conf')
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

snort_2931_alerts = 
  LOAD '$pcap'
  USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('/mnt/var/lib/snort-2931/etc/snort.conf')
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

-- snort_2905_alerts = 
-- LOAD 'snort_2905' AS (
--     ts:long,
--     sig:chararray,
--     severity:int,
--     message:chararray,
--     proto:chararray,
--     src:chararray,
--     sport:int,
--     dst:chararray,
--     dport:int
-- );
-- 
-- snort_2931_alerts = 
-- LOAD 'snort_2931' AS (
--     ts:long,
--     sig:chararray,
--     severity:int,
--     message:chararray,
--     proto:chararray,
--     src:chararray,
--     sport:int,
--     dst:chararray,
--     dport:int
-- );

snort_2905_sigs = FOREACH snort_2905_alerts GENERATE sig, message;
snort_2931_sigs = FOREACH snort_2931_alerts GENERATE sig, message;

snort_2905_grouped = GROUP snort_2905_sigs BY sig;
snort_2931_grouped = GROUP snort_2931_sigs BY sig;

snort_2905_summed = FOREACH snort_2905_grouped GENERATE group, COUNT(snort_2905_sigs);
snort_2931_summed = FOREACH snort_2931_grouped GENERATE group, COUNT(snort_2931_sigs);

snort_summed_joined = COGROUP snort_2905_summed BY group,
                              snort_2931_summed BY group;

new_only_filtered = FILTER snort_summed_joined BY (COUNT(snort_2905_summed) == 0);
new_only_flattened = FOREACH new_only_filtered GENERATE FLATTEN(snort_2931_summed);

DUMP new_only_flattened;
