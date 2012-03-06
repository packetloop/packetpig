register ./kraken-pcap-1.6.0.jar;
register ./tools-0.0.1-SNAPSHOT.jar;

packets = load '../data/web.pcap'  using com.blackfoundry.tools.pcap.PcapLoader() as (ts:chararray, version:int, ihl:int, tos:int, len:int, id:int, flagsiint, frag:int, ttl:int, proto:int, chksum:int, src:chararray, dst:chararray, sport:int, dport:int, syn:int, tcp_len:int);

syn = filter packets by syn==1;
tcp = filter packets by proto==6;

port_group = group tcp by src;

uniqcnt  = foreach port_group {
                   src      = tcp.src;
                   uniq_dst = distinct tcp.dst;
                   generate group, COUNT(uniq_dst);
};
dump uniqcnt;
