%DEFAULT prefix pig
RUN $prefix/include.pig;

%DEFAULT time 60
%DEFAULT field 'user-agent'
--%DEFAULT field 'set-cookie'

http_conversations = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.protocol.HTTPConversationLoader('$field') AS
    (
        ts:long,
        src:chararray,
        sport:int,
        dst:chararray,
        dport:int,
        field:chararray
    );


--Get the number of distinct fields's
all_field = group http_conversations by field; 

uniq_all = foreach all_field {
                  generate group, COUNT(http_conversations.field) AS count;

};
ordered = order uniq_all by count desc; 
--DUMP ordered;

--Get the number of user agents per source IP. Order descending.
src_http = group http_conversations by (src,field);

uniq_src  = foreach src_http {
                   uniq_src_field = distinct http_conversations.field;
                   generate group, COUNT(uniq_src_field);
};
DUMP uniq_src;
-- Find the countries
countries = foreach http_conversations GENERATE com.packetloop.packetpig.udf.geoip.Country(src) as country;

countries = GROUP countries BY country;

countries = FOREACH countries {
                  generate group, COUNT(countries);
};
--DUMP countries;
