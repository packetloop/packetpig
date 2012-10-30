echo "****************************************"
echo pig
echo "****************************************"

hadoop fs -copyToLocal s3n://packetpig/pig/include-emr.pig $HOME/.pigbootup
hadoop fs -copyToLocal s3n://packetpig/scripts.tar.gz scripts.tar.gz
mkdir -p /mnt/var/lib/packetpig
tar -zxf scripts.tar.gz -C /mnt/var/lib/packetpig

echo "****************************************"
echo debs
echo "****************************************"

sudo DEBIAN_PRIORITY=critical DEBIAN_FRONTEND=noninteractive aptitude -q -y install tcpdump libglib2.0-dev pkg-config libmagic-dev p0f flex bison build-essential libnet-dev libtool

echo "****************************************"
echo libpcap
echo "****************************************"

cd
hadoop fs -copyToLocal s3n://packetpig/libpcap-1.3.0.tar.gz libpcap-1.3.0.tar.gz
tar zxf libpcap-1.3.0.tar.gz
cd libpcap-1.3.0
./configure --prefix=/usr/local
make -j 8
sudo make install
sudo ldconfig

echo "****************************************"
echo libdnet
echo "****************************************"

cd
hadoop fs -copyToLocal s3n://packetpig/libdnet-1.12.tgz libdnet-1.12.tgz
tar zxf libdnet-1.12.tgz
cd libdnet-1.12
rm aclocal.m4
libtoolize --copy --force
aclocal
autoconf
./configure --prefix=/usr/local --enable-shared
make -j 8
sudo make install
sudo ldconfig

echo "****************************************"
echo daq
echo "****************************************"

cd
hadoop fs -copyToLocal s3n://packetpig/daq-1.1.1.tar.gz daq-1.1.1.tar.gz
tar zxf daq-1.1.1.tar.gz
cd daq-1.1.1
./configure --prefix=/usr/local
make
sudo make install
sudo ldconfig

echo "****************************************"
echo snort
echo "****************************************"

cd
hadoop fs -copyToLocal s3n://packetpig/snort-2.9.3.1.tar.gz snort-2.9.3.1.tar.gz
tar zxf snort-2.9.3.1.tar.gz
cd snort-2.9.3.1
./configure --prefix=/usr/local --enable-sourcefire
make -j 8
sudo make install

cd
hadoop fs -copyToLocal s3n://packetpig/snort-2905.tar.gz snort-2905.tar.gz
tar xzf snort-2905.tar.gz -C /mnt/var/lib

cd
hadoop fs -copyToLocal s3n://packetpig/snort-2931.tar.gz snort-2931.tar.gz
tar xzf snort-2931.tar.gz -C /mnt/var/lib

echo "****************************************"
echo python
echo "****************************************"

cd
hadoop fs -copyToLocal s3n://packetpig/Python-2.7.2.tar.bz2 Python-2.7.2.tar.bz2
tar jfx Python-2.7.2.tar.bz2
cd Python-2.7.2
./configure --prefix=/usr/local --with-threads --enable-shared
make -j 8
sudo make install
sudo ln -s /usr/local/lib/libpython2.7.so.1.0 /usr/lib/
sudo ln -s /usr/local/lib/libpython2.7.so /usr/

echo "****************************************"
echo easy_install
echo "****************************************"

cd
hadoop fs -copyToLocal s3n://packetpig/ez_setup.py ez_setup.py
sudo python ez_setup.py

echo "****************************************"
echo pip
echo "****************************************"

sudo easy_install pip

echo "****************************************"
echo pips
echo "****************************************"

sudo pip install python-magic

echo "****************************************"
echo scapy
echo "****************************************"

cd
hadoop fs -copyToLocal s3n://packetpig/scapy-latest.tar.gz scapy-latest.tar.gz
tar zxvf scapy-latest.tar.gz
cd scapy-2.1.0
sudo python setup.py install

echo "****************************************"
echo nids
echo "****************************************"

cd
hadoop fs -copyToLocal s3n://packetpig/pynids-0.6.1.tar.gz pynids-0.6.1.tar.gz
tar zxvf pynids-0.6.1.tar.gz
cd pynids-0.6.1
python setup.py build
sudo python setup.py install

echo "****************************************"
echo path hackery
echo "****************************************"

sudo ln -s /usr/sbin/tcpdump /usr/bin/tcpdump

