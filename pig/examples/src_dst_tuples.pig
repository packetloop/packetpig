register lib/kraken-pcap-1.6.0.jar;
register lib/packetloop.packetpig.jar;

packets = load 'data/web.pcap'  using com.packetloop.packetpig.pcap.PcapLoader() as (ts:chararray, version:int, ihl:int, tos:int, len:int, id:int, flagsiint, frag:int, ttl:int, proto:int, chksum:int, src:chararray, dst:chararray, sport:int, dport:int, syn:int, tcp_len:int);

syn = filter packets by syn==1;
tcp = filter packets by proto==6;

src_dst_group = group tcp by (src,dst);

cnt = foreach src_dst_group generate group, COUNT(tcp) as cnt_Packets, SUM(tcp.tcp_len) as sum_Packets;

order_cnt = order cnt by sum_Packets DESC;

store cnt into 'src_dst' using com.packetloop.packetpig.storage.JsonStorage();

