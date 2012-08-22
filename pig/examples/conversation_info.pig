%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT tcppath 'lib/scripts/tcp.py'

conversations = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.conversation.ConversationLoader('$tcppath') AS
    (
        ts:long,
        src:chararray,
        sport:int,
        dst:chararray,
        dport:int,
        end_state:chararray,
        timestamps,
        intervals
    );

STORE conversations INTO '$output/conversation_info';
