%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT time 60
%DEFAULT field 'user-agent'
--%DEFAULT field 'set-cookie'

http_conversations = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('$field', '$tcppath') AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    field:chararray
);

--Get the number of distinct fields
all_field = group http_conversations by field; 

uniq_all = foreach all_field {
                  generate group, COUNT(http_conversations.field) AS count;

};
ordered = order uniq_all by count desc; 

--Get the number of user agents per source IP. Order descending.
src_http = group http_conversations by (src,field);

uniq_src  = foreach src_http {
                   uniq_src_field = distinct http_conversations.field;
                   generate group, COUNT(uniq_src_field);
};

-- Find the countries
countries = foreach http_conversations GENERATE com.packetloop.packetpig.udf.geoip.Country(src) as country;

countries = GROUP countries BY country;

countries = FOREACH countries {
                  generate group, COUNT(countries);
};

STORE countries INTO '$output/http_fields';
