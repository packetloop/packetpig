#!/usr/bin/env python
'''Frontend for running Packetpig scripts in either local or mapreduce
mode.
'''

import os
import argparse
from pprint import pprint


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-f', dest='pig_path', required=True)
    parser.add_argument('-x', dest='mode', choices=['local', 'mapreduce'],
        default='local')
    parser.add_argument('-r', dest='pcap_path', default='data/web.pcap')
    parser.add_argument('-p', dest='hdfs_path')
    parser.add_argument('-s', dest='snort_conf', default='lib/snort/etc/snort.conf')
    parser.add_argument('-t', dest='tcp_path', default='lib/scripts/tcp.py')
    parser.add_argument('-d', dest='dns_path', default='lib/scripts/dns_parser.py')
    parser.add_argument('-n', dest='n', default='1')
    return parser.parse_args()

def prepend_hdfs_path(conf, path):
    if not path.startswith('hdfs://'):
        path = os.path.basename(path)
        path = '%s/%s' % (conf.hdfs_path, path)
    return path

def generate_cmd(conf):
    cmd = []
    cmd.append('pig -v')
    cmd.append('-x ' + conf.mode)

    if conf.mode == 'mapreduce':
        pig_path = prepend_hdfs_path(conf, conf.pig_path)
        pcap_path = prepend_hdfs_path(conf, conf.pcap_path)

        cmd.append('-f %s' % pig_path)
        cmd.append('-param pcap=%s' % pcap_path)
        cmd.append('-param includepath=%s/include-hdfs.pig' % conf.hdfs_path)

    if conf.mode == 'local':
        cmd.append('-f %s' % conf.pig_path)
        cmd.append('-param pcap=%s' % conf.pcap_path)

    cmd.append('-param output=output')
    cmd.append('-param n=%s' % conf.n)
    cmd.append('-param snortconfig=%s' % conf.snort_conf)
    #cmd.append('-param cvss=%s/snort-cvss.tsv' % conf.hdfs_path)
    cmd.append('-param tcppath=%s' % conf.tcp_path)
    cmd.append('-param dnspath=%s' % conf.dns_path)

    pprint(cmd)
    print

    return ' '.join(cmd)


def main():
    conf = parse_args()
    cmd = generate_cmd(conf)
    print('Executing %s' % cmd)
    os.system(cmd)

if __name__ == '__main__':
    main()

