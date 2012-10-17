%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT field ''
%DEFAULT tcppath 'lib/scripts/tcp.py'
%DEFAULT snortconfig 'lib/snort/etc/snort.conf'

http = LOAD '/pl/dumps/174f501a-d6e3-11e1-bec6-7f3db9d5953d' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('user-agent') AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    request:chararray,
    fields:tuple()
);

snort_alerts = LOAD '/pl/dumps/174f501a-d6e3-11e1-bec6-7f3db9d5953d' USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader() AS (
    ts:long,
    sig:chararray,
    priority:int,
    message:chararray,
    proto:chararray,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int
);

fingerprints = LOAD '/pl/dumps/174f501a-d6e3-11e1-bec6-7f3db9d5953d' USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    os:chararray
);

attacker_fingerprint_info = JOIN
                            snort_alerts BY (src, sport, dst, dport),
                            fingerprints BY (src, sport, dst, dport);

attacker_fingerprints = FOREACH attacker_fingerprint_info GENERATE kkkkkkkkkkkkkkkkk

dump attacker_fingerprints;

--attacker_useragents = JOIN
--                        attacker_fingerprints BY (src, sport, dst, dport),
--                        http BY (src, sport, dst, dport);
--
--STORE attacker_useragents INTO '$output/user_info';

