%DEFAULT includepath pig/include.pig
RUN $includepath;

ngram_all   = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.packet.PacketNgramLoader('', '1');
ngram_ssh   = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.packet.PacketNgramLoader('tcp:22', '1');
ngram_smtp  = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.packet.PacketNgramLoader('tcp:25', '1');
ngram_dns   = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.packet.PacketNgramLoader('udp:53', '1');
ngram_http  = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.packet.PacketNgramLoader('tcp:80', '1');
ngram_https = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.packet.PacketNgramLoader('tcp:443', '1');

-- The number prefix is to help concatenation ordering
STORE ngram_all   INTO 'output/ngram-chart/0-all' using PigStorage(',');
STORE ngram_http  INTO 'output/ngram-chart/1-http' using PigStorage(',');
STORE ngram_https INTO 'output/ngram-chart/2-https' using PigStorage(',');
STORE ngram_ssh   INTO 'output/ngram-chart/3-ssh' using PigStorage(',');
STORE ngram_dns   INTO 'output/ngram-chart/4-dns' using PigStorage(',');
STORE ngram_smtp  INTO 'output/ngram-chart/5-smtp' using PigStorage(',');

