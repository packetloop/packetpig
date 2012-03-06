#!/usr/bin/env python

import colorsys
import sys

import ubigraph

class Dns:

    def __init__(self):
        self.ubi = ubigraph.Ubigraph()
        self.ubi.clear()
        self.names = {}

    def go(self, filename):
        for line in open(sys.argv[1]):
            line = line[1:-2]
            self.add(line)

    def add(self, line):
        print line
        try:
            ts, ttl, query, domain, _ = line.split(',')
        except ValueError:
            return
        dbits = domain.split('.')
        dbits.append('-')

        for a in xrange(len(dbits) - 1):
            from_section = '.'.join(dbits[a:])
            to_section = '.'.join(dbits[a + 1:])

            self.node(from_section, to_section, (a + 1) / 2)

    def cached_node(self, key):
        if key in self.names:
            return self.names[key]

        si = len(key.split('.'))
        s = 2. / si
        c = colorsys.hls_to_rgb(si * .1, .5, .8)
        c = [ int(256 * a) for a in c ]
        cstr = "#%02X%02X%02X" % tuple(c)
        if si < 7:
            l = key
        else:
            l = None

        v = self.ubi.newVertex(shape="sphere", color=cstr,
            label=l,
            size=s)
        self.names[key] = v
        return v

    def node(self, fr, to, s):
        frn = self.cached_node(fr)
        ton = self.cached_node(to)
        self.ubi.newEdge(frn, ton, strength=s)

def main():
    Dns().go(sys.argv[1])

if __name__ == '__main__':
    main()

