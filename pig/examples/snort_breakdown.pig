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


prio1= FILTER snort_alerts BY priority == 1;
prio2= FILTER snort_alerts BY priority == 2;
prio3= FILTER snort_alerts BY priority == 3;

prio1_grouped = GROUP prio1 BY (ts / $time * $time);
prio1_summary = FOREACH prio1_grouped GENERATE group, COUNT(prio1) AS prio1_count;

prio2_grouped = GROUP prio2 BY (ts / $time * $time);
prio2_summary = FOREACH prio2_grouped GENERATE group, COUNT(prio2) AS prio2_count;

prio3_grouped = GROUP prio3 BY (ts / $time * $time);
prio3_summary = FOREACH prio3_grouped GENERATE group, COUNT(prio3) AS prio3_count;

joined = JOIN prio1_summary BY group full, prio3_summary BY group;
summary = FOREACH joined GENERATE prio1_summary::group, prio1_count, prio3_count;

-- This doesn't
--joined = JOIN prio1_summary BY group, prio2_summary BY group, prio3_summary BY group;
--summary = FOREACH joined GENERATE prio1_summary::group, prio1_count, prio2_count, prio3_count;


STORE summary INTO '$output/snort_breakdown';
