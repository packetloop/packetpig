%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT tcppath 'lib/scripts/tcp.py'

conversations = LOAD '$pcap'
  USING com.packetloop.packetpig.loaders.pcap.conversation.ConversationLoader('$tcppath') AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    end_state:chararray,
    timestamps,
    intervals
);

r = FOREACH conversations GENERATE FLATTEN(com.packetloop.packetpig.udf.util.Explode(intervals)) AS interval;
r = FOREACH r GENERATE (int)((double)interval * 1000) AS interval;
r = GROUP r BY interval;
r = FOREACH r GENERATE group, COUNT(r.interval);

STORE r INTO '$output/packet_latency_histogram';
