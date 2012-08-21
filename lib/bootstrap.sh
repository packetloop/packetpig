echo "****************************************"
echo debs
echo "****************************************"

sudo apt-get install -y tcpdump libnids1.21 libglib2.0-dev pkg-config libnet1-dev libyaml-dev libpcap-dev libmagic-dev p0f 

hadoop fs -copyToLocal s3n://packetloop-emr/libdnet_1.12-1_amd64.deb libdnet_1.12-1_amd64.deb
hadoop fs -copyToLocal s3n://packetloop-emr/daq_0.5-1_amd64.deb daq_0.5-1_amd64.deb
hadoop fs -copyToLocal s3n://packetloop-emr/snort_2.9.0.5-1_amd64.deb snort_2.9.0.5-1_amd64.deb
sudo dpkg -i libdnet_1.12-1_amd64.deb
sudo dpkg -i daq_0.5-1_amd64.deb
sudo dpkg -i snort_2.9.0.5-1_amd64.deb

sudo ln -sf /usr/lib/snort_dynamicengine /usr/local/lib/snort_dynamicengine
sudo ln -sf /usr/lib/snort_dynamicpreprocessor /usr/local/lib/snort_dynamicpreprocessor

echo "****************************************"
echo python
echo "****************************************"

wget http://python.org/ftp/python/2.7.2/Python-2.7.2.tar.bz2
tar jfx Python-2.7.2.tar.bz2
cd Python-2.7.2
./configure --with-threads --enable-shared
make -j 4
sudo make install
sudo ln -s /usr/local/lib/libpython2.7.so.1.0 /usr/lib/
sudo ln -s /usr/local/lib/libpython2.7.so /usr/
cd ..

echo "****************************************"
echo easy_install
echo "****************************************"

wget http://peak.telecommunity.com/dist/ez_setup.py
sudo python ez_setup.py

echo "****************************************"
echo pip
echo "****************************************"

sudo easy_install pip

echo "****************************************"
echo pips
echo "****************************************"

# TODO: use requirements.txt
sudo pip install pycassa==1.6.0
sudo pip install mrjob==0.3.3.2
sudo pip install PyYaml==3.10
sudo pip install python-daemon==1.5.5
sudo pip install lockfile==0.9.1
sudo pip install six==1.1.0
sudo pip install bulbs==0.3

echo "****************************************"
echo scapy
echo "****************************************"

wget http://www.secdev.org/projects/scapy/files/scapy-latest.tar.gz
tar zxvf scapy-latest.tar.gz
cd scapy-2.1.0
sudo python setup.py install
cd ..

echo "****************************************"
echo nids
echo "****************************************"

wget http://jon.oberheide.org/pynids/downloads/pynids-0.6.1.tar.gz
tar zxvf pynids-0.6.1.tar.gz
cd pynids-0.6.1
python setup.py build
sudo python setup.py install
cd ..

sudo ln -s /usr/sbin/tcpdump /usr/bin/tcpdump

echo "****************************************"
echo snort
echo "****************************************"

hadoop fs -copyToLocal s3n://packetloop-emr/snort.tar.gz snort.tar.gz
tar -xzf snort.tar.gz -C /mnt/var/lib

echo "****************************************"
echo pig
echo "****************************************"

hadoop fs -copyToLocal s3n://packetpig/.pigbootup $HOME/.pigbootup

