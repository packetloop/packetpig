%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60

-- for local mode: uncomment the next line and comment the one after that
--%DEFAULT old_snort_conf 'lib/snort-2905/etc/snort.conf'
%DEFAULT old_snort_conf '/mnt/var/lib/snort-2905/etc/snort.conf'

-- for local mode: uncomment the next line and comment the one after that
--%DEFAULT new_snort_conf 'lib/snort-2931/etc/snort.conf'
%DEFAULT new_snort_conf '/mnt/var/lib/snort-2931/etc/snort.conf'

snort_old_alerts = 
    LOAD '$pcap'
    USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('$old_snort_conf')
    AS (
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

snort_new_alerts = 
    LOAD '$pcap'
    USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('$new_snort_conf')
    AS (
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

snort_joined = COGROUP snort_old_alerts BY sig, snort_new_alerts BY sig;

new_only_filtered = FILTER snort_joined BY (COUNT(snort_old_alerts) == 0);
new_only_flattened = FOREACH new_only_filtered GENERATE FLATTEN(snort_new_alerts);
new_only_summary = FOREACH new_only_filtered GENERATE group, COUNT(snort_new_alerts);

STORE new_only_flattened INTO '$output/snort_comparison_new';
STORE new_only_summary INTO '$output/snort_comparison_summary';
