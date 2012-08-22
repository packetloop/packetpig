%DEFAULT includepath pig/include.pig
RUN $includepath;

dns = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.packet.DnsAllPacketLoader() AS (
    ts:long,
    id:long,
    mode:chararray,
    name:chararray,
    addr:chararray,
    ttl:int,
    srcIP:chararray,
    dstIP:chararray,
    class:int,
    type:int
);

DUMP dns;
--STORE dns INTO '$output/dns' USING PigStorage(',');

