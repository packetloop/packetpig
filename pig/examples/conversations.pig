%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60

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
packets = FOREACH packets GENERATE ts, ip_src, tcp_sport, ip_dst, tcp_dport, ip_id, ip_total_length;

conversations = LOAD '$pcap' using com.packetloop.packetpig.loaders.pcap.conversation.ConversationLoader() AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    end_state:chararray
);
conversations = FOREACH conversations GENERATE ts, src, sport, dst, dport;

r = JOIN
        conversations   BY (ts / $time * $time,    src,     sport,    dst,     dport),
        packets         BY (ts / $time * $time, ip_src, tcp_sport, ip_dst, tcp_dport);

r = GROUP r BY (conversations::src, conversations::sport, conversations::dst, conversations::dport);
r = FOREACH r GENERATE SUM(r.packets::ip_total_length);

STORE r INTO '$output/conversations' USING PigStorage(',');

