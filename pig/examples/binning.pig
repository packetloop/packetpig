%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60 
--%DEFAULT time 3600

packets = load '$pcap' using com.packetloop.packetpig.loaders.pcap.packet.PacketLoader() AS (
    ts,

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

tcp = FILTER packets BY ip_proto == 6;
udp = FILTER packets BY ip_proto == 17;

tcp_grouped = GROUP tcp BY (ts / $time * $time);
tcp_summary = FOREACH tcp_grouped GENERATE group, SUM(tcp.tcp_len) AS tcp_len;

udp_grouped = GROUP udp BY (ts / $time * $time);
udp_summary = FOREACH udp_grouped GENERATE group, SUM(udp.udp_len) AS udp_len;

bw_grouped = GROUP packets BY (ts / $time * $time);
bw_summary = FOREACH bw_grouped GENERATE group, SUM(packets.ip_total_length) AS bw;

joined = JOIN tcp_summary BY group, udp_summary BY group, bw_summary BY group;
summary = FOREACH joined GENERATE tcp_summary::group, tcp_len, udp_len, bw;

--DUMP joined;
STORE summary INTO '$output/binning' USING PigStorage(',');
