register ./kraken-pcap-1.6.0.jar;
register ./tools-0.0.1-SNAPSHOT.jar;

packets = load '../data/web.pcap'  using com.blackfoundry.tools.pcap.PcapLoader() as (ts:chararray, version:int, ihl:int, tos:int, len:int, id:int, flagsiint, frag:int, ttl:int, proto:int, chksum:int, src:chararray, dst:chararray, sport:int, dport:int, syn:int, tcp_len:int);

src_grouped = group packets by src;
src_summary = foreach src_grouped generate group, COUNT(packets), SUM(packets.tcp_len);
ordered_by_sum = order src_summary by SUM(packets.tcp_len)
dump ordered_by_sum;
