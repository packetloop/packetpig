%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT filter ''
%DEFAULT n '1'

ngram = LOAD '$pcap'
  USING com.packetloop.packetpig.loaders.pcap.packet.PacketNgramLoader('$filter', '$n');

STORE ngram INTO '$output/ngram' using PigStorage(',');
--DUMP ngram;

-- plot(x=data$V3, y=data$V4, type='h')
-- plot(sort(data$V4, decreasing=TRUE), type='h')
