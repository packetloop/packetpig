RUN cd snort-2.9.11.1/ &&\
  ./configure  --prefix /usr/local/snort --enable-ipv6 --enable-gre --enable-mpls --enable-targetbased  --enable-ppm --enable-perfprofiling   --enable-zlib --enable-reload && make && make install &&\
  groupadd snort && useradd -g snort snort && ln -s /usr/local/snort/bin/snort /usr/sbin/ && ln -s /usr/local/snort/etc /etc/snort &&\
  mkdir -p /usr/local/snort/var/log && chown snort:snort /usr/local/snort/var/log && ln -s /usr/local/snort/var/log /var/log/snort &&\
  ln -s /usr/local/snort/lib/snort_dynamicpreprocessor /usr/local/lib/snort_dynamicpreprocessor &&\
  ln -s /usr/local/snort/lib/snort_dynamicengine /usr/local/lib/snort_dynamicengine 

#snort rules
RUN mkdir /usr/local/snort/lib/snort_dynamicrules && ln -s /usr/local/snort/lib/snort_dynamicrules /usr/local/lib/snort_dynamicrules &&\
  chown -R snort:snort /usr/local/snort && ldconfig

#Install glib
RUN cd /src &&\
  wget https://ftp.gnome.org/pub/gnome/sources/glib/2.2/glib-2.2.3.tar.gz && tar -zxvf glib-2.2.3.tar.gz  &&\
  cd glib-2.2.3 && ./configure && make && make install

#Install p0f
RUN cd /src &&\
  wget http://lcamtuf.coredump.cx/p0f3/releases/p0f-3.09b.tgz &&\
  tar -zxvf p0f-3.09b.tgz && cd p0f-3.09b/ && sed -i "s/p0f.fp/\/etc\/p0f\/p0f.fp/g" config.h && make && cp p0f /usr/local/bin && mkdir /etc/p0f &&\
  cp p0f.fp /etc/p0f/

#Install Pynids for 64 bit
RUN cd /src &&\
  wget https://jon.oberheide.org/files/pynids-0.6.1.tar.gz &&\
  tar -zxvf pynids-0.6.1.tar.gz && cd pynids-0.6.1 && tar -zxvf libnids-1.24.tar.gz && cd libnids-1.24/ &&\
  ./configure CFLAGS=-fPIC --disable-libglib --disable-libnet --disable-shared && make && make install &&\
  cd .. && python setup.py build && python setup.py install

#Set Java Environment
PATH=/usr/lib/jvm/java-8-openjdk-amd64/:$PATH
PPD=/src/packetpig/:$PATH

# Packetpig
RUN cd /src/ &&\
   cd packetpig &&\
  lib/scripts/tcp.py -r data/web.pcap -om http_headers -of tsv | less &&\
  lib/scripts/dns_parser.py -r data/web.pcap && mkdir out &&\
  pig -x local -f pig/examples/binning.pig -param pcap=data/web.pcap -param output=output && more output/binning/part-r-00000
