%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT snortconfig 'lib/snort/etc/snort.conf'
%DEFAULT field 'user-agent'

snort_alerts = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('$snortconfig') AS (
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

http_conversations = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('$field') AS (
    ts:long,

    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    field:chararray
);

snort_http = JOIN
                snort_alerts BY (src, sport, dst, dport),
                http_conversations BY (src, sport, dst, dport);

STORE snort_http INTO 'output/snort_http' USING PigStorage(',');
