%DEFAULT includepath pig/include.pig
RUN $includepath;

packets = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.packet.PacketLoader() AS (
    ts:long,

    ip_version:int,
    ip_header_length:int,
    ip_tos:int,
    ip_total_length:int,
    ip_id:int,
    ip_flags:int,
    ip_frag_offset:int,
    ip_ttl:int,
    ip_proto:int,
    ip_checksum:int,
    ip_src:chararray,
    ip_dst:chararray,

    tcp_sport:int,
    tcp_dport:int
);

tcp = FILTER packets BY tcp_sport > 0;
packets = FOREACH tcp GENERATE tcp_sport, tcp_dport, ip_total_length;

outgoing = GROUP packets BY tcp_dport;
incoming = GROUP packets BY tcp_sport;

joined = JOIN outgoing BY group, incoming BY group;

lengths = FOREACH joined GENERATE outgoing::group, SUM(outgoing::packets.ip_total_length) + SUM(incoming::packets.ip_total_length);

STORE lengths INTO '$output/protocol_size_histogram';
