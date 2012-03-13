%DEFAULT includepath pig/include.pig
RUN $includepath;

dns = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.DNSConversationLoader() AS (
    ts:long,
    id:long,
    mode:chararray,
    name:chararray,
    addr:chararray,
    ttl:int
);

STORE dns INTO 'output/ubigraph-dns' USING PigStorage(',');

