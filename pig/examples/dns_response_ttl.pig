%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT dnspath 'lib/scripts/dns_parser.py'

dns = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.DNSConversationLoader('$dnspath') AS (
    ts:long,
    id:long,
    mode:chararray,
    name:chararray,
    addr:chararray,
    ttl:int
);

response = FILTER dns BY mode == 'response' AND ttl > 0;

-- Output domain, ttl and the number of times seen. The key is domain/ttl.
domain_grouped = GROUP response BY (name,ttl);

cnt_by_ttl = FOREACH domain_grouped GENERATE FLATTEN(group), COUNT(response);

STORE cnt_by_ttl INTO '$output/dns_response_ttl' USING PigStorage(',');

-- Check r/examples/dns_ttl.r for plots
