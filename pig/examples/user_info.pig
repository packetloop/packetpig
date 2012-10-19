%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT field ''
%DEFAULT tcppath 'lib/scripts/tcp.py'
%DEFAULT snortconfig 'lib/snort/etc/snort.conf'

set default_parallel 800

--http = LOAD '/pl/dumps/boobs' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('user-agent') AS (
http = LOAD 'output/http/part-m-00000' AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    fields:chararray,
    request:chararray
);

--snort_alerts = LOAD '/pl/dumps/boobs' USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('lib/snort-2931/etc/snort.conf') AS (
snort_alerts = LOAD 'output/snort_alerts/part-m-00000' AS (
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

--fingerprints = LOAD '/pl/dumps/boobs' USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
fingerprints = LOAD 'output/fingerprints/part-m-00000' AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    os:chararray
);

locations = 
    FOREACH snort_alerts
        GENERATE
            ts, src, sport, dst, dport,
            com.packetloop.packetpig.udf.geoip.Country(src) AS country,
            com.packetloop.packetpig.udf.geoip.City(src) AS city,
            com.packetloop.packetpig.udf.geoip.LatLon(src) AS latlon;

joined = 
    COGROUP
        snort_alerts BY (src, sport, dst, dport),
        fingerprints BY (src, sport, dst, dport),
        http         BY (src, sport, dst, dport),
        locations    BY (src, sport, dst, dport);

summary = 
    FOREACH joined
        GENERATE
            FLATTEN(snort_alerts.sig),
            FLATTEN(snort_alerts.message),
            FLATTEN(http.fields),
            FLATTEN(fingerprints.os),
            group.src, group.sport, group.dst, group.dport,
            FLATTEN(snort_alerts.ts),
            FLATTEN(locations.country),
            FLATTEN(locations.city),
            FLATTEN(locations.latlon);

summary = DISTINCT summary;

dump summary;

