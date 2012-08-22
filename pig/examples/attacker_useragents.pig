%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT snortconfig 'lib/snort/etc/snort.conf'
%DEFAULT tcppath 'lib/scripts/tcp.py'
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

http_conversations = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('$tcppath', '$field') AS (
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

useragent_frequency = GROUP snort_http BY field;
summary = FOREACH useragent_frequency GENERATE group, COUNT(snort_http) AS count;
summary = ORDER summary BY count DESC;

STORE summary INTO '$output/attacker_useragents';
