# Packetpig Installation Instructions

## Note

I will expand this guide over time starting with Ubuntu and then adding
Mac OSX at some stage in the future.

## Ubuntu 11.10 

Start off with a basic Ubuntu 11.10 32bit or 64bit desktop build. You
can obviously achieve the same results on Ubuntu Server however the
desktop comes pre-installed with an X environment allowing you to view
visualisations in a browser quickly enough.

Create a new apt source so that we can leverage the Cloudera
distributions for Hadoop and Pig.

    sudo vi /etc/apt/sources.list.d/cloudera.list

Add the following lines.

    deb http://archive.cloudera.com/debian maverick-cdh3 contrib
    deb-src http://archive.cloudera.com/debian maverick-cdh3 contrib

And then add the Cloudera key.

    sudo apt-get install curl
    sudo curl -s http://archive.cloudera.com/debian/archive.key | sudo apt-key add -

Update the running system

    sudo apt-get update

Install all the required packages for the Packetpig platform and accept
the dependencies.

    sudo apt-get install hadoop-0.20 hadoop-pig git libnids-dev libnids1.21 python-nids chromium-browser libmagic-dev ipython r-base r-base-dev python2.7-dev libnet1-dev python-pip flex bison libpcap0.8 libpcap0.8-dev openjdk-6-jdk

Install the following Python modules.

   sudo pip install python-magic

Then you need to install libdnet, fix libdnet ;), snort, glib, p0f and pynids from source.

    wget http://libdnet.googlecode.com/files/libdnet-1.12.tgz
    tar -zxvf libdnet-1.12.tgz
    cd libdnet-1.12/
    ./configure
    make
    sudo make install

Fixing libdnet

    sudo cp /usr/local/lib/libdnet.1.0.1 /usr/local/lib/libdnet.so.1.0.1
    sudo ldconfig
    sudo updatedb

Install DAQ

    wget http://www.snort.org/downloads/1850
    tar -zxvf 1850
    cd daq-1.1.1/
    ./configure
    make
    sudo make install

Install Snort

    wget http://www.snort.org/downloads/1862
    tar -zxvf 1862
    cd snort-2.9.3.1/
    ./configure  --enable-ipv6 --enable-gre --enable-mpls --enable-targetbased  --enable-decoder-preprocessor-rules --enable-ppm --enable-perfprofiling   --enable-zlib --enable-reload
    make
    sudo make install

Install glib

    wget ftp://ftp.gtk.org/pub/gtk/v2.2/glib-2.2.3.tar.bz2
    bunzip2 glib-2.2.3.tar.bz2
    tar -xvf glib-2.2.3.tar
    cd glib-2.2.3
    ./configure
    make
    sudo make install

Install p0f

    wget http://lcamtuf.coredump.cx/p0f3/releases/p0f-3.06b.tgz
    tar -zxvf p0f-3.06b.tgz
    cd p0f-3.06b/
    vi config.h and change the define FP_FILE line from "p0f.fp" to "/etc/p0f/p0f.fp"
    make
    cp p0f /usr/local/bin/
    cp p0f.fp /etc/p0f/

Install pynids

    wget http://jon.oberheide.org/pynids/downloads/pynids-0.6.1.tar.gz
    tar -zxvf pynids-0.6.1.tar.gz
    cd pynids-0.6.1
    python setup.py build
    sudo python setup.py install


Once all the packages are installed the R packages for time series and
plotting need to be installed.

    sudo R
    chooseCRANmirror()
    install.packages(c("zoo", "xts","ggplot2"))

Accept all defaults. You may get an error on ggplot2, I am working on it
;)

Pig and Hadoop require the JAVA_HOME environment variable to be set.

    sudo vi /etc/environment
    JAVA_HOME=/usr/lib/jvm/java-6-openjdk/

Now all the base software is installed we need to install the Packetpig
platform and run some simple tests.

    cd ~/Documents
    git clone https://github.com/packetloop/packetpig.git
    cd packetpig
    lib/scripts/tcp.py -r data/web.pcap -om http_headers -of tsv | less
    lib/scripts/dns_parser.py -r data/web.pcap
    mkdir out
    snort -c lib/snort-2931/etc/snort.conf -A fast -y -l out -r data/web.pcap
    vi out/alert

Both tcp.py and dns_parser.py should extract information out of data/web.pcap and display it to the screen. Now you are ready to run some Packetpig queries.

    pig -x local -f pig/examples/binning.pig -param pcap=data/web.pcap -param output=output

This will result in something like this. 

    2012-04-16 16:15:33,970 [main] INFO  org.apache.pig.backend.hadoop.executionengine.mapReduceLayer.MapReduceLauncher - Success!

You can confirm it has worked by.

    more output/binning/part-r-00000
    1322643600,171738,142808,338610

## Mac OSX 10.7 (Lion)

Before you start you need XCode installed or more specifically the XCode Command Line Tools. Within XCode Preferences there is a "Downloads" menu that allows you to install the command line tools.

The next step is to make sure you have Java installed. I ran this command to check, if it doesn't find Java it prompts you to install it.

    /usr/libexec/java_home --request

After installing it you should set the JAVA_HOME environment variable using something like.

    export JAVA_HOME=`/usr/libexec/java_home`

The Homebrew package manager allows you to install most of the components required for Packetpig quickly and easily. To install Homebrew run this command.

    /usr/bin/ruby -e "$(/usr/bin/curl -fksSL https://raw.github.com/mxcl/homebrew/master/Library/Contributions/install_homebrew.rb)"

Once Homebrew is installed run the brew doctor and also the brew update command to make sure you have the latest brews.

    brew doctor
    brew update

After running brew doctor I received a warning "Your Xcode is configured with an invalid path" to fix it I entered

    sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer/

Once brew is working correctly you can install the bulk of the requirements for Packetpig.

    brew install git hadoop pig libnids libmagic snort p0f wget

For some of the Python modules you can't use Homebrew so I used the pip package mangaer.

    sudo easy_install pip
    sudo pip insatll ipython
    sudo pip install python-magic

Then lastly you need to install pynids from source.

    wget http://jon.oberheide.org/pynids/downloads/pynids-0.6.1.tar.gz
    tar -zxvf pynids-0.6.1.tar.gz
    cd pynids-0.6.1
    python setup.py build
    sudo python setup.py install

A good test to ensure that everything on the Python side is working is to clone the Packetpig repository and run the following commands from within the packetpig directory.

    git clone https://github.com/packetloop/packetpig.git
    cd packetpig
    lib/scripts/tcp.py -r data/web.pcap -om http_headers -of tsv | less
    lib/scripts/dns_parser.py -r data/web.pcap

Both tcp.py and dns_parser.py should extract information out of data/web.pcap and display it to the screen. Now you are ready to run some Packetpig queries.

    pig -x local -f pig/examples/binning.pig -param pcap=data/web.pcap

This will result in something like this. 

    2012-04-16 16:15:33,970 [main] INFO  org.apache.pig.backend.hadoop.executionengine.mapReduceLayer.MapReduceLauncher - Success!

You can confirm it has worked by.

    more output/binning/part-r-00000
    1322643600,171738,142808,338610

For some of the visualisations you will want R and RStudio installed. Install the Mac OSX package for R at http://cran.us.r-project.org/ and the RStudio package from http://rstudio.org. Once you have R or RStudio installed you can manually install the 'zoo', 'xts' and 'ggplot2' packages.
