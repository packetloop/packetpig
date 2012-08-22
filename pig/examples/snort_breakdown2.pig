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

-- Get totals
events = GROUP snort_alerts all;
events = FOREACH events {
          a_src = distinct snort_alerts.src;
          a_dst = distinct snort_alerts.dst;
          a_sigs = distinct snort_alerts.sig;
          GENERATE COUNT(snort_alerts) as total_attacks, COUNT(a_src) as total_sources, COUNT(a_dst) as total_destinations, COUNT(a_sigs) as distinct_attacks;
};
--DUMP events;

-- Get distinct attackers and distinct attack per bins
events = GROUP snort_alerts BY ((ts/$time*$time));
events = FOREACH events {
          u_src = distinct snort_alerts.src;
          u_sig = distinct snort_alerts.sig;
          u_dst = distinct snort_alerts.dst;
          u_dport = distinct snort_alerts.dport;
          --GENERATE group, FLATTEN(u_src), u_sig, COUNT(u_src), COUNT(u_sig);
          GENERATE group, COUNT(u_src), COUNT(u_sig), COUNT(u_dst), COUNT(u_dport), COUNT(snort_alerts);
};
--STORE events into 'out/snort/distinct' using PigStorage(',');

-- Get all attacks by priority
events = GROUP snort_alerts BY ((ts/$time*$time),priority);
events = FOREACH events GENERATE group.$0, group.$1, COUNT(snort_alerts) as total;

-- Get all attacks by priority by attack  
events = GROUP snort_alerts BY ((ts/$time*$time),priority,sig);
events = FOREACH events GENERATE group.$0, group.$1, group.$2, snort_alerts.message, COUNT(snort_alerts) as total;

-- Get all attacks by priority by attack  
events = GROUP snort_alerts BY ((ts/$time*$time),priority,sig);
events = FOREACH events GENERATE group.$0, group.$1, group.$2, snort_alerts.message, COUNT(snort_alerts) as total;

STORE events INTO '$output/snort_breakdown2';
