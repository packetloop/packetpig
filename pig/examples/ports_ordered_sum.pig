register ./kraken-pcap-1.6.0.jar;
register ./tools-0.0.1-SNAPSHOT.jar;

packets = load '../data/web.pcap'  using com.blackfoundry.tools.pcap.PcapLoader() as (ts:chararray, version:int, ihl:int, tos:int, len:int, id:int, flagsiint, frag:int, ttl:int, proto:int, chksum:int, src:chararray, dst:chararray, sport:int, dport:int, syn:int, tcp_len:int);

syn = filter packets by syn==1;
tcp = filter packets by proto==6;

port_group = group tcp by dport;
port_cnt = foreach port_group generate group, COUNT(tcp) as count_tcp, SUM(tcp.tcp_len) as sum_tcp;
port_result = ORDER port_cnt BY sum_tcp DESC;
dump port_result;
