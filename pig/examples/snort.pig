%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT src null
%DEFAULT dst null
%DEFAULT sport null
%DEFAULT dport null
%DEFAULT snortconfig 'lib/snort/etc/snort.conf'

snort_alerts =
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
STORE snort_alerts INTO '$output/snort';

