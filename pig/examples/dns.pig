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

DUMP dns;
--STORE dns INTO '$output/dns' USING PigStorage(',');

