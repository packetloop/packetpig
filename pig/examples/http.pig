%DEFAULT prefix pig
RUN $prefix/include.pig;

%DEFAULT time 60
%DEFAULT field ''
--%DEFAULT field 'set-cookie'

http = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('$field') AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    request:chararray,
    fields:tuple()
);

STORE http INTO 'output/http';

