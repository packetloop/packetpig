%DEFAULT includepath pig/include.pig
RUN $includepath;
%DEFAULT time 60
%DEFAULT field 'user-agent'
%DEFAULT tcppath 'lib/scripts/tcp.py'


fingerprints = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    os:chararray,
    app:chararray,
    dist:chararray,
    lang:chararray,
    params:chararray,
    raw_freq:chararray,
    raw_mtu:chararray,
    raw_sig:chararray,
    uptime:chararray
);

http_conversations = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('$tcppath', '$field') AS
    (
        ts:long,
        src:chararray,
        sport:int,
        dst:chararray,
        dport:int,
        field:chararray
    );

first_group = group fingerprints by src;

second_group = group http_conversations by src;
--illustrate first_group;
--illustrate second_group;
joined = JOIN second_group by group, first_group by group;

summary = FOREACH joined GENERATE FLATTEN(second_group::group), fingerprints.os, http_conversations.field;

--DUMP summary;

STORE summary INTO '$output/p0f_http';

