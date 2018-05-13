%DEFAULT includepath pig/include.pig

-- First, register jar dependencies
RUN $includepath;

fingerprints = LOAD '/p0f-input/input.pcap' USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
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


mapped = GROUP fingerprints BY src;

reduced = FOREACH mapped {
                   uniq = DISTINCT fingerprints.raw_sig;
		   start = '$start';
		   finish = '$finish';
                   GENERATE group, COUNT(uniq);
};


STORE reduced INTO 'mongodb://localhost:27017/devices' USING  com.mongodb.hadoop.pig.MongoStorage();



