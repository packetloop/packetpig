<table><tr>
<td><img width="100" height="100" src="https://raw.github.com/packetloop/packetpig/master/packetpig.png" />
<td>
<h1>Packetpig</h1>
<p>An <b>Open Source Big Data Security Analytics</b> tool that analyses <a href="http://en.wikipedia.org/wiki/Pcap">pcap</a> files using <a href="http://pig.apache.org/">Apache Pig</a>.</p>
<p>
Created by <a href="https://www.packetloop.com/">Packetloop</a>.
See the <a href="http://blog.packetloop.com/search/label/packetpig">Packetloop Blog</a> for Packetpig tips and tricks.
</p>
</table>

## Note

If Markdown is painful in your text editor, run lib/scripts/readme.py from this directory and it'll generate a README.html for you. You'll need the markdown python module installed.

## Overview

If you want to run the pig scripts you have to set the pcap parameter for the pcap you want to use.

There is a small, test pcap file called data/web.pcap that you can test prior to running on your own pcaps.

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

A frontend to lib/scripts/tcp.py which gives you a record per TCP connection, along with src, dst, end state, timestamps of each packet, and intervals between each packet.

### FingerprintLoader

A frontend to p0f, giving you an operating system for each packet in a pcap.

See pig/examples/p0f.pig for correlating Snort with p0f.

### SnortLoader

A frontend to Snort which produces a record for each alert triggered.

## Packetloop UDFs

##

## Scripts

### pigrun.py

A lightweight wrapper around Pig. It is a handy tool when switching between local and mapreduce mode without having to change many arguments, e.g. HDFS paths. It also has a basic set of sane default arguements to help retyping them all the time. An example usage of pigrun:

    # ./pigrun.py -f pig/charts/ngram-chart.pig

This will generate the command:

    pig -v -x local -f pig/charts/ngram-chart.pig -param pcap=data/web.pcap -param snortconfig=etc/snort.conf

The list of available arguments are listed when running `--help` as an argument, and checking out the source code is handy too.

### lib/run_emr

    # lib/run_emr -f PIG_SCRIPT -r S3_LOCATION [-c INSTANCE_COUNT] [-t INSTANCE_TYPE] [-b BID_PRICE] [-i]

    e.g.

    # lib/run_emr -f s3://your-data/analyse.pig -r s3://your-data/captures/ -c 4 -t m1.large -b 0.01

Specify -i to get an interactive pig shell on the emr cluster.
Check -h for full options or refer to X for examples.

The following environment variables will configure the emr credentials for you:

    # AWS_ACCESS_KEY_ID
    # AWS_SECRET_ACCESS_KEY
    # EMR_KEYPAIR
    # EMR_KEYPAIR_PATH
    # EC2_REGION (optional, defaults to us-east-1)

### put.sh

Upload a single file into HDFS into a predetermined location. You should specify the env variable HDFS_MASTER to specify where the destination is. The env
variable PREFIX determines the path to place the uploaded file.

### prepare-hdfs.sh

Uses `put.sh` to upload all `.pig` and `.jar` files into HDFS.

## Visualisations

### Overview

The visualisations are pure HTML and JavaScript. You'll need to run a dumb web server that just serves files.

Python does this well with a one-liner:

    python -m SimpleHTTPServer 8888

Run this in the root of the project, then access a visualisation via
http://localhost:8888/vis/cube/cube.html for example.

WebGL will require a browser that supports WebGL.

### Globe (WebGL) ✔

The globe is a WebGL visualisation which displays the Earth with lines extruding out from it. The colour of the lines represent average severity in Snort attacks and the height of the lines for number of attacks.

It expects the format to be `"lat lon,avgsev,attacks"`.

It's in `vis/globe/globe.html` and an example pig script is `pig/globe/globe.pig`.

### Trigram Cube (WebGL)

Trigram cube is a WebGL visualisation displaying 3 dimensions of data, designed for visualising trigrams.

The `vis/cube/ngram.pig` file outputs a list of ngraphs. A trigram of 256 variations of bytes produces 16777216 values, which is quite a fair bit to visualise. To reduce this, this is a script called `lib/scripts/reduce-trigram.py` where it condenses the 16M values into a summarised output.

First, run `vis/cube/ngram.pig' on a pcap, then run the `reduce-trigram.py` script over the output:

    # pig -x local -f pig/cube/cube-ngram.pig -param pcap=data/web.pcap
    # lib/scripts/reduce-trigram.py output/ngram/part-m-00000 > output/ngram/summarised

The generated `output/ngram/summarised` file can now be used in the visualisation at `vis/cube/cube.html`.

### DNS Directed Graph (Ubigraph)

This is a visualisation that uses Ubigraph. It links domains by their subdomain parts.

Download Ubigraph from http://ubietylab.net/ubigraph/content/Downloads/ then extract and run `bin/ubigraph_server`. This will create a window where the visualisation will appear. When that's running, execute the `vis/ubigraph/dns.py` with the output of `pig/ubigraph/dns.pig`, e.g.:

    # vis/ubigraph/dns.py output/ubigraph-dns/part-m-00000

### Side-by-Side Charts

These charts allow you to compare different sets of data together.

Use either histogram or timeseries data in this format:

    filter,category,timestamp,value

or

    filter,category,title,value

The vis is in `vis/charts/main.html`.

#### Unigram

The Unigram pig script at `pig/charts/ngram-chart.pig` runs multiple n-gram jobs over your pcap file. You'll need to concatenate all the files together using a command similar to this:

  # ./pigrun.py -f pig/charts/ngram-chart.pig
  # cat output/ngram-chart/*/* > output/ngram-chart/combined

Note: If you inspect the output of `ngram-chart.pig`, you'll notice one of the output files, "ngram-chart/all", has no filter name. To fix this so that the charts all have labels, run this command over the output:

  # sed 's/,,/,All Protocols,/g' output/ngram-chart/combined > output/ngram-chart/combined-tweaked

Drag the combined-tweaked into the visualisation at `vis/charts/main.html`.

### Choropleth

Choropleth is a map of the Earth with countries shaded to a particular colour based on some data.

The input expected for the Choropleth is "country code,value". Basically drag it into the drop zone and the countries get highlighted.

It's in `vis/world/world.html` and an example pig script is `pig/choropleth/snort.pig`

## Pig Scripts

pig/examples/ contains various examples for you to try out.

### pig/examples/attacker_useragents.pig

For each web-related snort alert found in a set of captures, the attacker
User-Agent header is discovered.

Arguments:

- pcap: path to the capture (or directory of captures) to work on
- time: the bin period (default: 60)
- field: the http header to extract (default: user-agent)
- snortconfig: the path to the snort config (default: built-in snort config)

### pig/examples/bandwidth.pig

Sum ip packet length per time bin.

Arguments:

- pcap: path to the capture (or directory of captures) to work on
- time: the bin period (default: 60)

### pig/examples/binning.pig

Collect packets into bins of $time seconds.
Additionally group by tcp, udp, and bandwidth.

Arguments:

- pcap: path to the capture (or directory of captures) to work on
- time: the bin period (default: 60)

### pig/examples/conversation_info.pig

Conversation info, which includes a list of intervals within the conversation.

Arguments:

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/conversations.pig

Join conversations to packets and shows 4tuple + conversation length.

Arguments:

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/dns.pig

Shows DNS queries and responses.

Arguments:

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/dns_response_ttl.pig

Show DNS response TTLs.

Arguments:

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/extract_files.pig

Extract files out of conversations.

Arguments:

- pcap: path to the capture (or directory of captures) to work on
- path: directory to store files in

### pig/examples/histogram.pig

Create a packet length histogram.

Arguments:

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/ngram.pig

Create an ngram.

Arguments:

- pcap: path to the capture (or directory of captures) to work on
- filter: string in the format of 'proto:port' e.g. tcp:80
- n: the 'n' in 'ngram'. 1 gives 0-255, 2 gives 0-65535 etc.

### pig/examples/p0f.pig

Find p0f fingerprints of snort attackers.

Arguments:

- pcap: path to the capture (or directory of captures) to work on
- snortconfig: the path to the snort config (default: built-in snort config)

### pig/examples/p0f_fingerprint.pig

Show p0f fingerprints of packets.

Arguments:

- pcap: path to the capture (or directory of captures) to work on

### pig/examples/protocol_size_histogram.pig

Histogram for packets, ordered by the packet volume on dport.

Arguments:

- pcap: path to the capture (or directory of captures) to work on

