%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT field ''
%DEFAULT tcppath 'lib/scripts/tcp.py'

http = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('$field', '$tcppath') AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    request:chararray,
    fields:tuple()
);

STORE http INTO '$output/http';

