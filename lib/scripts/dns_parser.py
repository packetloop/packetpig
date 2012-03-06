#!/usr/bin/env python

import os
import sys
import argparse
import traceback
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'impacket/impacket'))

import nids
import dns

class DNSProcess:
    def __init__(self):
        pass

    def run(self, args):
        nids.chksum_ctl([('0.0.0.0/0', False)])  # disable checksumming
        nids.param('scan_num_hosts', 0)  # disable portscan detection
        nids.param('filename', args.filename)
        nids.init()

        nids.register_udp(self.udp_handler)

        try:
            nids.run()
        except nids.error, e:
            print >> sys.stderr, 'nids/pcap error:', e
            sys.exit(-1)
        except Exception, e:
            print >> sys.stderr, 'Exception', e
            traceback.print_exc(file=sys.stderr)
            sys.exit(-1)

    def udp_handler(self, addrs, payload, pkt):
        (src, sport), (dst, dport) = addrs
        if sport == 53 or dport == 53:
            d = dns.DNS(payload)

            id = d.get_transaction_id()
            flags = d.get_flags()

            if flags & dns.DNSFlags.QR_RESPONSE:
                mode = 'response'
            else:
                mode = 'query'

            res = {
                    'ts': nids.get_pkt_ts(),
                    'mode': mode,
                    'id': id,
                    'questions': [],
                    'answers': [],
                    'authoritatives': [],
                    'additionals': []
            }

            def add_values(key, keys, values):
                info = {}

                values = list(values)
                values.reverse()
                values = tuple(values)

                for value in values:
                    info[keys.pop()] = value
                res[key].append(info)

            qdcount = d.get_qdcount()
            if qdcount > 0:
                questions = d.get_questions()
                questions.reverse()
                while questions:
                    add_values('questions', ['qname', 'qtype', 'qclass'], questions.pop())

            ancount = d.get_ancount()
            if ancount > 0:
                answers = d.get_answers()
                answers.reverse()
                while answers:
                    add_values('answers', ['qname', 'qtype', 'qclass', 'qttl', 'qrdata'], answers.pop())

            nscount = d.get_nscount()
            if nscount > 0:
                authoritatives = d.get_authoritatives()
                authoritatives.reverse()
                while authoritatives:
                    add_values('authoritatives', ['qname', 'qtype', 'qclass', 'qttl', 'qrdata'], authoritatives.pop())

            arcount = d.get_arcount()
            if arcount > 0:
                additionals = d.get_additionals()
                additionals.reverse()
                while additionals:
                    add_values('additionals', ['qname', 'qtype', 'qclass', 'qttl', 'qrdata'], additionals.pop())

            print json.dumps(res)

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('-r', dest='filename')
    args = ap.parse_args()

    n = DNSProcess()
    n.run(args)
