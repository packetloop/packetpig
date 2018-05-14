

fingerprints = LOAD '/src/packetpig/data/web.pcap USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
    ts:chararray,
    client_ip:chararray,
    server_ip:chararray,
    d:chararray,
    connection:chararray,
    mtu:chararray,
    g:chararray,
    raw_ip:chararray,
);


shared_ips = GROUP client_ip BY raw_ip;


uniqcnt = FOREACH shared_ips {
                   client_ip      = cip;
                   uniq_os = DISTINCT raw_ip;
                   GENERATE group, COUNT(os);
};
