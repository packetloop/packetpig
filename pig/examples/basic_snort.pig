%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT snortconfig 'lib/snort/etc/snort.conf'

snort_alerts =
  LOAD '$pcap'
  USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('$snortconfig')
  AS (ts:long, sig:chararray, priority:int, message:chararray, proto:chararray,
    src:chararray, dst:chararray, sport:int, dport:int);

DUMP snort_alerts;
