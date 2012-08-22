%DEFAULT includepath pig/include.pig
RUN $includepath;

packets = LOAD '$pcap' using com.packetloop.packetpig.loaders.pcap.packet.PacketLoader() AS (
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
    tcp_dport:int,
    tcp_seq_id:long,
    tcp_ack_id:long,
    tcp_offset:int,
    tcp_ns:int,
    tcp_cwr:int,
    tcp_ece:int,
    tcp_urg:int,
    tcp_ack:int,
    tcp_psh:int,
    tcp_rst:int,
    tcp_syn:int,
    tcp_fin:int,
    tcp_window:int,
    tcp_len:int,

    udp_sport:int,
    udp_dport:int,
    udp_len:int,
    udp_checksum:chararray
);

syn = FILTER packets BY tcp_syn == 1;
tcp = FILTER packets BY ip_proto == 6;

port_group = GROUP tcp BY ip_src;

uniqcnt = FOREACH port_group {
                   src      = tcp.ip_src;
                   uniq_dst = DISTINCT tcp.ip_dst;
                   GENERATE group, COUNT(uniq_dst);
};

STORE uniqcnt INTO '$output/src_distinct_destinations';
