%DEFAULT includepath pig/include.pig
RUN $includepath;

dns = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.DNSConversationLoader() AS (
    ts:long,
    id:long,
    mode:chararray,
    name:chararray,
    addr:chararray,
    ttl:int
);

response = filter dns by mode=='response' and ttl!=0;

-- Output domain, ttl and the number of times seen. The key is domain/ttl.
domain_grouped = GROUP response BY (name,ttl);

cnt_by_ttl = FOREACH domain_grouped GENERATE FLATTEN(group), COUNT(response);

STORE cnt_by_ttl into 'output/dns_response_ttl' using PigStorage(',');

-- Check r/examples/dns_ttl.r for plots
