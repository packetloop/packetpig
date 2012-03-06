%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT tcppath 'lib/scripts/tcp.py'

conversations = LOAD 'data/web.pcap' USING com.packetloop.packetpig.loaders.pcap.conversation.ConversationLoader() AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    end_state:chararray,
    timestamps,
    intervals
);

packets = LOAD 'data/web.pcap' USING com.packetloop.packetpig.loaders.pcap.packet.PacketLoader() AS (
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

outgoing = JOIN
    conversations   BY (ts / 60 * 60, dst, dport, src, sport),
    packets         BY (ts / 60 * 60, ip_src, tcp_sport, ip_dst, tcp_dport);

incoming = JOIN
    conversations   BY (ts / 60 * 60, dst, dport, src, sport),
    packets         BY (ts / 60 * 60, ip_dst, tcp_dport, ip_src, tcp_sport);

incoming_grouped = GROUP incoming BY (conversations::ts / 60 * 60, conversations::dst, conversations::dport, conversations::src, conversations::sport);
outgoing_grouped = GROUP outgoing BY (conversations::ts / 60 * 60, conversations::dst, conversations::dport, conversations::src, conversations::sport);

conversations_packets = JOIN
    incoming_grouped BY
        (conversations.ts,
         conversations.src,
         conversations.sport,
         conversations.dst,
         conversations.dport),
    outgoing_grouped BY
        (conversations.ts,
         conversations.src,
         conversations.sport,
         conversations.dst,
         conversations.dport);

DUMP conversations_packets;

/*
blah = GROUP conversations_packets BY (
    incoming::conversations::ts,
    incoming::conversations::src,
    incoming::conversations::sport,
    incoming::conversations::dst,
    incoming::conversations::dport);

blah = FOREACH blah GENERATE group;
DUMP blah;

-- conversations_packets.tcp_dport for dports, ip_total_length for packet length, etc etc.
conversations_protos = FOREACH conversations_packets_grouped GENERATE group, conversations_packets.ip_total_length AS len;

conversation_packet_lengths = FOREACH conversations_protos GENERATE group, FLATTEN(len) AS len;
grouped_conversation_lengths = GROUP conversation_packet_lengths BY group;
conversation_lengths = FOREACH grouped_conversation_lengths GENERATE group, SUM(conversation_packet_lengths.len) AS len;

ordered_conversations = ORDER conversation_lengths BY len DESC;
top_conversations = LIMIT ordered_conversations 10;

convo_packets = JOIN top_conversations BY group.dport, packets BY tcp_dport;

convo_packets_lengths = FOREACH convo_packets GENERATE tcp_dport, ip_total_length AS len;
packet_length_freq = GROUP convo_packets_lengths BY tcp_dport;
freq_summary = FOREACH packet_length_freq GENERATE group AS tcp_dport, FLATTEN(convo_packets_lengths.len) AS len;

grouped = GROUP freq_summary BY (tcp_dport, len);
summary = FOREACH grouped GENERATE group.tcp_dport, group.len, COUNT(freq_summary);
STORE summary INTO 'sony';
*/

-- sp <- ggplot(data, aes(x=data$V1, y=data$V3)) + geom_point(shape=1)
-- sp + facet_grid(V2 ~ .)
