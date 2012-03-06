# Packetpig

## Note

If Markdown is painful in your text editor, run lib/scripts/readme.py from this
directory and it'll generate a README.html for you. You'll need the markdown
python module installed.

## Overview

If you want to run the pig scripts you have to set the pcap parameter for the
pcap you want to use.

There is a small, test pcap file called data/web.pcap that you can test prior
to running on your own pcaps.

You can run locally:

    pig -x local \
        -f pig/examples/binning.pig \
        -param pcap=data/web.pcap

or with a cluster setup:

    pig -x mapreduce \
        -f hdfs://server/pig/binning.pig \
        -param pcap=hdfs://server/pig/web.pcap

You'll need to put files into HDFS to leverage the cluster setup.
Also edit pig/include-hdfs.pig to specify your HDFS URI.

## Packetloop Loaders

### ConversationLoader

A frontend to lib/scripts/tcp.py which gives you a record per TCP connection,
along with src, dst, end state, timestamps of each packet, and intervals
between each packet.

### FingerprintLoader

A frontend to p0f, giving you an operating system for each packet in a pcap.

See pig/examples/p0f.pig for correlating Snort with p0f.

### SnortLoader

A frontend to Snort which produces a record for each alert triggered.

## Packetloop UDFs

##

## Scripts

### put.sh

Upload a single file into HDFS into a predetermined location. You should specify the env variable HDFS_MASTER to specify where the destination is. The env
variable PREFIX determines the path to place the uploaded file.

### prepare-hdfs.sh

Uses `put.sh` to upload all `.pig` and `.jar` files into HDFS.

## Visualisations

### Overview

The visualisations are pure HTML and JavaScript. You'll need to run a dumb web
server that just serves files.

Python does this well with a one-liner:

    python -m SimpleHTTPServer 8888

Run this in the root of the project, then access a visualisation via
http://localhost:8888/vis/cube/cube.html for example.

### Choropleth

The input expected for the Choropleth is "country code,value". Basically drag it into the drop zone and the countries get highlighted.

It's in vis/world/world.html and an example pig script is pig/choropleth/snort.pig

### N-gram cube

The ngram.pig file can output a list of ngraphs from a pcap specifying a packet
filter and N.

The output is a single line CSV file that should have 256 ^ N elements and can
be imported into vis/cube/cube.html

## Pig Scripts

pig/examples/ contains various examples for you to try out.

### pig/examples/attacker_useragents.pig

For each web-related snort alert found in a set of captures, the attacker
User-Agent header is discovered.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on
- time: the bin period (default: 60)
- field: the http header to extract (default: user-agent)
- snortconfig: the path to the snort config (default: built-in snort config)

### pig/examples/bandwidth.pig

Sum ip packet length per time bin.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on
- time: the bin period (default: 60)

### pig/examples/binning.pig

Collect packets into bins of $time seconds.
Additionally group by tcp, udp, and bandwidth.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on
- time: the bin period (default: 60)

### pig/examples/conversation_packet_intervals.pig

Conversation info, which includes a list of intervals within the
conversation.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/conversations.pig

Join conversations to packets and shows 4tuple + conversation length.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/dns.pig

Shows DNS queries and responses.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/dns_response_ttl.pig

Show DNS response TTLs.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/extract_files.pig

Extract files out of conversations.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on
- path: directory to store files in

### pig/examples/histogram.pig

Create a packet length histogram.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/ngram.pig

Create an ngram.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on
- filter: string in the format of 'proto:port' e.g. tcp:80
- n: the 'n' in 'ngram'. 1 gives 0-255, 2 gives 0-65535 etc.

### pig/examples/p0f.pig

Find p0f fingerprints of snort attackers.

#### Arguments
- pcap: path to the capture (or directory of captures) to work on
- snortconfig: the path to the snort config (default: built-in snort config)

### pig/examples/p0f_fingerprint.pig

Show p0f fingerprints of packets.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/protocol_size_histogram.pig

Histogram for packets, ordered by the packet volume on dport.

#### Arguments

- pcap: path to the capture (or directory of captures) to work on

