#!/usr/bin/env python
'''
Process a PCAP file into a line per TCP conversation with payload processing
such as HTTP and SMTP.
'''

import gzip
import zlib
import os
import mimetypes
import tempfile
import hashlib
from copy import copy
import traceback
import json
import re
import argparse
import sys

import nids
import magic
import cStringIO as StringIO

class StreamProcess:

    def parse_args(self):
        ap = argparse.ArgumentParser(description=__doc__)
        ap.add_argument('-r', dest='filename')
        ap.add_argument('-of', dest='output_format', default='json',
            help='json or tsv')
        ap.add_argument('-om', dest='output_mode', default='base',
            help='base, http_headers, http_body')
        ap.add_argument('-xf', dest='extract_files', default=False,
            action='store_true')
        ap.add_argument('-i', dest='mime_type', default=None)
        return ap.parse_args()

    def run(self, config):
        self.config = config
        nids.chksum_ctl([('0.0.0.0/0', False)])  # disable checksumming
        nids.param('scan_num_hosts', 0)  # disable portscan detection
        if self.config.filename:
            nids.param('filename', self.config.filename)
        else:
            nids.param('filename', '-')
        nids.init()

        self.stream_handler = StreamHandler(self.config)
        nids.register_tcp(self.stream_handler.handle)

        try:
            nids.run()
        except nids.error, e:
            print >> sys.stderr, 'nids/pcap error:', e
            sys.exit(-1)
        except Exception, e:
            print >> sys.stderr, 'Exception', e
            traceback.print_exc(file=sys.stderr)
            sys.exit(-1)


class StreamHandler:

    VERBS = 'get put post delete head http/1.0 http/1.1'.split()

    END_STATES = {
        nids.NIDS_CLOSE: 'close',
        nids.NIDS_TIMEOUT: 'timeout',
        nids.NIDS_RESET: 'reset',
    }

    def __init__(self, config):
        self.config = config
        self.packet_timestamps = []

    def handle(self, tcp):

        self.packet_timestamps.append(nids.get_pkt_ts())

        # Established
        if tcp.nids_state == nids.NIDS_JUST_EST:
            # save the timestamp we just added. :P
            self.packet_timestamps = [self.packet_timestamps[-1]]
            tcp.client.collect = 1
            tcp.server.collect = 1

        # Data received
        elif tcp.nids_state == nids.NIDS_DATA:
            tcp.discard(0)

        # End
        elif tcp.nids_state in self.END_STATES:
            self.emit(tcp)
            self.packet_timestamps = []

    def emit(self, tcp):
        (saddr, sport), (daddr, dport) = tcp.addr

        out = {}

        fields = 'ts src sport dst dport'.split()

        out['ts'] = self.packet_timestamps[0]
        out['timestamps'] = self.packet_timestamps
        out['src'] = saddr
        out['sport'] = sport
        out['dst'] = daddr
        out['dport'] = dport

        out['end_state'] = self.END_STATES[tcp.nids_state]

        out['cdata'] = tcp.client.data
        out['sdata'] = tcp.server.data
        out['cdatalen'] = len(tcp.client.data)
        out['sdatalen'] = len(tcp.server.data)

        HttpHandler().process(out)

        if self.config.output_mode != 'file':
            del(out['cdata'])
            del(out['sdata'])

        if self.config.output_format == 'json':
            print json.dumps(out, ensure_ascii=False)

        if self.config.output_format == 'tsv':

            base = [str(out[f]) for f in fields]

            if 'http' not in out:
                return

            if self.config.output_mode == 'http_body':
                HttpBodyDumpEmitter(self.config).emit(base, out)
                return

            if self.config.output_mode == 'http_headers':
                for convo in out['http']:
                    split = convo['status'].split()
                    if len(split) > 1 and split[0].lower() in self.VERBS:
                        b1 = copy(base)
                        b1 += [convo['status'].replace('\n', ' '),
                               convo['direction']]

                        for header, value in convo['headers'].items():
                            b2 = copy(b1)
                            b2 += [header.replace('\n', ' '),
                                    value.replace('\n', ' ')]
                            print '\t'.join(b2)

                return

            print '\t'.join(base)


class HttpBodyDumpEmitter:

    def __init__(self, config):
        self.config = config

    def emit(self, base, out):
        for convo in out['http']:
            b = copy(base)

            fp, filename = tempfile.mkstemp(prefix='http-body-dump')
            payload = convo['payload']
            os.write(fp, payload)
            os.close(fp)

            mag = magic.Magic(mime=True)
            mime = mag.from_file(filename)
            if not mime:
                mime = ''
            ext = mimetypes.guess_extension(mime)

            filetype = magic.from_file(filename).replace(',', '')

            if ext:
                os.rename(filename, filename + ext)
                filename = filename + ext
            else:
                ext = ''

            if self.config.mime_type:
                if '/' in self.config.mime_type:
                    if mime != self.config.mime_type:
                        continue
                else:
                    if '.' in self.config.mime_type:
                        if ext != self.config.mime_type:
                            continue
                    else:
                        if ext[1:] != self.config.mime_type:
                            continue

            b += [
                filetype,
                mime,
                ext,
                hashlib.md5(payload).hexdigest(),
                hashlib.sha1(payload).hexdigest(),
                hashlib.sha256(payload).hexdigest(),
                str(os.stat(filename).st_size),
                ]

            if self.config.extract_files:
                b += [filename]
            else:
                os.unlink(filename)

            print '\t'.join(b)


class ParsingException(Exception):
    pass


class HttpHandler:

    def http_split(self, data):
        # Split the data into header and data
        bits = data.split('\r\n\r\n', 1)
        if len(bits) != 2:
            return
        raw_header, payload = bits

        # Split the status line from the rest of the header
        bits = raw_header.split('\r\n', 1)
        if len(bits) != 2:
            return
        status, header = bits

        # Process header lines into a dict
        headers = re.findall(r"(?P<name>.*?): (?P<value>.*?)\r\n",
            header)
        headers = [(a.lower(), b) for a, b in headers]
        headers = dict(headers)

        return raw_header, status, headers, payload

    def extract_http_parts(self, data):
        ret = {}
        http_bits = self.http_split(data)
        if not http_bits:
            return
        raw_header, status, headers, payload = http_bits

        ret['status'] = status
        ret['headers'] = headers
        ret['payload'] = payload

        content_length = int(headers.get('content-length', 0))

        if content_length:
            part_payload = payload[0:content_length]

        elif headers.get('transfer-encoding', '').lower() == 'chunked':
            remaining = payload
            part_payload = ''
            chunksize = -1
            while remaining and chunksize:
                bits = remaining.split('\r\n', 1)
                if len(bits) != 2:
                    break
                chunksize, remaining = bits
                try:
                    chunksize = int(chunksize, 16)
                except ValueError:
                    raise ParsingException('Incorrect chunk header')
                part_payload += remaining[0:chunksize]
                remaining = remaining[chunksize + 2:]

        else:
            # No Content-Length and no Chunked Transfer-Encoding
            part_payload = ''

        if headers.get('connection', '').lower() == 'keep-alive':
            the_rest = payload[len(part_payload):]
        else:
            the_rest = ''

        part_payload = self.decompress(part_payload, headers)

        return ret, the_rest

    def decompress(self, data, headers):
        encoding = headers.get('content-encoding', None)
        if not encoding:
            return data
        if encoding == 'gzip':
            f = StringIO.StringIO(data)
            try:
                data = gzip.GzipFile(fileobj=f).read()
            except (IOError, zlib.error), e:
                raise ParsingException('Can not decompress: %s' % e)
        else:
            raise ParsingException('Unknown encoding type: %s' % encoding)
        return data

    def process(self, inp):
        http_conversations = []

        def go(rest, direction):
            while 1:
                try:
                    response = self.extract_http_parts(rest)
                except ParsingException, e:
                    print >> sys.stderr, e
                    break
                if not response:
                    break
                data, rest = response
                data['direction'] = direction
                http_conversations.append(data)

        go(inp['sdata'], 's')
        go(inp['cdata'], 'c')

        if http_conversations:
            inp['http'] = http_conversations


if __name__ == '__main__':
    n = StreamProcess()
    args = n.parse_args()
    n.run(args)
