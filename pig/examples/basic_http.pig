%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
--%DEFAULT field 'etag'
--%DEFAULT field 'referer'
%DEFAULT field 'user-agent'
--%DEFAULT field 'set-cookie'

http_conversations = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('$field') AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    field:chararray
);

DUMP http_conversations;
