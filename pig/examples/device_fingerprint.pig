%DEFAULT includepath pig/include.pig
RUN $includepath;

fingerprints = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    os:chararray,
    app:chararray,
    dist:chararray,
    lang:chararray,
    params:chararray,
    raw_freq:chararray,
    raw_mtu:chararray,
    raw_sig:chararray,
    uptime:chararray
);

shared_ip = GROUP fingerprints BY src;
device_count = FOREACH shared_ip GENERATE flatten(group),flatten(COUNT(raw_sig));
-- STORE shared_ip INTO 'shared_ips.csv'
STORE device_count INTO 'device_count.csv';

