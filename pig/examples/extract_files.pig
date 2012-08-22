%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT tcppath 'lib/scripts/tcp.py'
%DEFAULT path 'tmp'
%DEFAULT mime ''

streams =
  LOAD '$pcap'
  USING com.packetloop.packetpig.loaders.pcap.file.ConversationFileLoader('$tcppath', '$path', '$mime')
  AS (
    ts,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    filetype:chararray,
    mimetype:chararray,
    ext:chararray,
    md5:chararray,
    sha1:chararray,
    sha256:chararray,
    size:long,
    path:chararray,
    name:chararray
  );

STORE streams INTO '$output/extract_files';
