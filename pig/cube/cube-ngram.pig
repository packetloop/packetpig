%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT filter ''
%DEFAULT n '3'

ngram = LOAD '$pcap'
  USING com.packetloop.packetpig.loaders.pcap.packet.PacketNgramLoader('$filter', '$n');

STORE ngram INTO 'output/cube-ngram' using PigStorage(',');

