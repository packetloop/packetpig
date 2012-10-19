%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT field ''
%DEFAULT tcppath 'lib/scripts/tcp.py'
%DEFAULT snortconfig 'lib/snort/etc/snort.conf'

set default_parallel 800

--http = LOAD 'output/http/part-m-00000' AS (
http = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('user-agent') AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    fields:chararray,
    request:chararray
);

--snort_alerts = LOAD 'output/snort_alerts/part-m-00000' AS (
snort_alerts = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('lib/snort-2931/etc/snort.conf') AS (
    ts:long,
    sig:chararray,
    severity:int,
    message:chararray,
    proto:chararray,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int
);

--fingerprints = LOAD 'output/fingerprints/part-m-00000' AS (
fingerprints = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    os:chararray
);

high_severity = 
    FILTER snort_alerts
        BY (severity == 1);

locations = 
    FOREACH high_severity
        GENERATE
            ts, src, sport, dst, dport,
            com.packetloop.packetpig.udf.geoip.Country(src) AS country,
            com.packetloop.packetpig.udf.geoip.City(src) AS city,
            com.packetloop.packetpig.udf.geoip.LatLon(src) AS latlon;

joined = 
    COGROUP
        high_severity BY (src, sport, dst, dport),
        fingerprints BY (src, sport, dst, dport),
        http         BY (src, sport, dst, dport),
        locations    BY (src, sport, dst, dport);

summary = 
    FOREACH joined
        GENERATE
            FLATTEN(high_severity.sig),
            FLATTEN(high_severity.message),
            FLATTEN(http.fields),
            FLATTEN(fingerprints.os),
            group.src, group.sport, group.dst, group.dport,
            FLATTEN(high_severity.ts),
            FLATTEN(locations.country),
            FLATTEN(locations.city),
            FLATTEN(locations.latlon);

summary = DISTINCT summary;

STORE summary INTO 'output/user_info';

