FROM ubuntu:precise
MAINTAINER Michael Baker <cloudjunky@gmail.com>

RUN echo "deb http://archive.cloudera.com/debian maverick-cdh3 contrib" > /etc/apt/sources.list.d/cloudera.list
RUN echo "deb-src http://archive.cloudera.com/debian maverick-cdh3 contrib" >> /etc/apt/sources.list.d/cloudera.list
RUN echo "deb http://us.archive.ubuntu.com/ubuntu/ precise universe" >> /etc/apt/sources.list
RUN echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-updates universe" >> /etc/apt/sources.list

RUN apt-get install curl wget -y --force-yes
RUN curl -s http://archive.cloudera.com/debian/archive.key | apt-key add -
RUN apt-get update -y --force-yes

RUN apt-get install build-essential hadoop-0.20 hadoop-pig git-core libnids-dev libnids1.21 libmagic-dev ipython python2.7-dev libnet1-dev python-pip flex bison libpcap0.8 libpcap0.8-dev openjdk-6-jdk libpcre3 libpcre3-dev pkg-config gettext -y --force-yes

RUN pip install python-magic argparse

#Install libdnet
RUN mkdir /src;\
  cd /src;\
  wget http://libdnet.googlecode.com/files/libdnet-1.12.tgz;\
  tar -zxvf libdnet-1.12.tgz;\
  cd libdnet-1.12/;\
  ./configure;\
  make;\
  make install;

#Fix libdnet
RUN cp /usr/local/lib/libdnet.1.0.1 /usr/local/lib/libdnet.so.1.0.1 &&\
  ldconfig

#Install DAQ
RUN cd /src &&\
  wget http://www.snort.org/downloads/1850 &&\
  tar -zxvf 1850 &&\
  cd daq-1.1.1/ &&\
  ./configure && make && make install

#Install Snort

RUN cd /src &&\
  wget http://www.snort.org/downloads/1862 &&\
  tar -zxvf 1862 &&\
  cd snort-2.9.3.1/ &&\
  ./configure  --prefix /usr/local/snort --enable-ipv6 --enable-gre --enable-mpls --enable-targetbased  --enable-ppm --enable-perfprofiling   --enable-zlib --enable-reload && make && make install &&\
  groupadd snort && useradd -g snort snort && ln -s /usr/local/snort/bin/snort /usr/sbin/ && ln -s /usr/local/snort/etc /etc/snort &&\
  mkdir -p /usr/local/snort/var/log && chown snort:snort /usr/local/snort/var/log && ln -s /usr/local/snort/var/log /var/log/snort &&\
  ln -s /usr/local/snort/lib/snort_dynamicpreprocessor /usr/local/lib/snort_dynamicpreprocessor &&\
  ln -s /usr/local/snort/lib/snort_dynamicengine /usr/local/lib/snort_dynamicengine &&\
  mkdir /usr/local/snort/lib/snort_dynamicrules && ln -s /usr/local/snort/lib/snort_dynamicrules /usr/local/lib/snort_dynamicrules &&\
  chown -R snort:snort /usr/local/snort && ldconfig

#Install glib
RUN cd /src &&\
  wget ftp://ftp.gtk.org/pub/gtk/v2.2/glib-2.2.3.tar.bz2 && bunzip2 glib-2.2.3.tar.bz2 && tar -xvf glib-2.2.3.tar &&\
  cd glib-2.2.3 && ./configure && make && make install

#Install p0f
RUN cd /src &&\
  wget http://lcamtuf.coredump.cx/p0f3/releases/p0f-3.06b.tgz &&\
  tar -zxvf p0f-3.06b.tgz && cd p0f-3.06b/ && sed -i "s/p0f.fp/\/etc\/p0f\/p0f.fp/g" config.h && make && cp p0f /usr/local/bin && mkdir /etc/p0f &&\
  cp p0f.fp /etc/p0f/

#Install Pynids for 64 bit
RUN cd /src &&\
  wget http://jon.oberheide.org/pynids/downloads/pynids-0.6.1.tar.gz &&\
  tar -zxvf pynids-0.6.1.tar.gz && cd pynids-0.6.1 && tar -zxvf libnids-1.24.tar.gz && cd libnids-1.24/ &&\
  ./configure CFLAGS=-fPIC --disable-libglib --disable-libnet --disable-shared && make && make install &&\
  cd .. && python setup.py build && python setup.py install

#Set Java Environment
#ENV JAVA_HOME /usr/lib/jvm/java-6-openjdk/
ENV JAVA_HOME /usr/lib/jvm/java-6-openjdk-amd64/
ENV PPD /src/packetpig/

#Clone and run Packetpig
RUN cd /src/ &&\
  git clone https://github.com/packetloop/packetpig.git && cd packetpig &&\
  lib/scripts/tcp.py -r data/web.pcap -om http_headers -of tsv | less &&\
  lib/scripts/dns_parser.py -r data/web.pcap && mkdir out &&\
  pig -x local -f pig/examples/binning.pig -param pcap=data/web.pcap -param output=output && more output/binning/part-r-00000
