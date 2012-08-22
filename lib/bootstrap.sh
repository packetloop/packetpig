echo "****************************************"
echo pig
echo "****************************************"

hadoop fs -copyToLocal s3n://packetpig/pig/include-emr.pig $HOME/.pigbootup
hadoop fs -copyToLocal s3n://packetpig/scripts.tar.gz scripts.tar.gz
mkdir -p /mnt/var/lib/packetpig
tar -zvxf scripts.tar.gz -C /mnt/var/lib/packetpig

echo "****************************************"
echo debs
echo "****************************************"

echo "deb http://mirror.cse.iitk.ac.in/debian/ testing main contrib" | sudo sh -c "cat >> /etc/apt/sources.list"

sudo apt-get install -qy --force-yes python2.7 tcpdump libnids1.21 libglib2.0-dev pkg-config libnet1-dev libpcap-dev libmagic-dev p0f 

hadoop fs -copyToLocal s3n://packetloop-emr/libdnet_1.12-1_amd64.deb libdnet_1.12-1_amd64.deb
hadoop fs -copyToLocal s3n://packetloop-emr/daq_0.5-1_amd64.deb daq_0.5-1_amd64.deb
hadoop fs -copyToLocal s3n://packetloop-emr/snort_2.9.0.5-1_amd64.deb snort_2.9.0.5-1_amd64.deb
sudo dpkg -i libdnet_1.12-1_amd64.deb
sudo dpkg -i daq_0.5-1_amd64.deb
sudo dpkg -i snort_2.9.0.5-1_amd64.deb

sudo ln -sf /usr/lib/snort_dynamicengine /usr/local/lib/snort_dynamicengine
sudo ln -sf /usr/lib/snort_dynamicpreprocessor /usr/local/lib/snort_dynamicpreprocessor

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

sudo pip install python-magic

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

