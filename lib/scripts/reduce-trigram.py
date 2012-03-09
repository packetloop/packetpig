#!/usr/bin/env python
'''
Summarises a trigram into smaller components and in a format that can be read
by vis/cube/cube.html

Expects an input from pig/cube/cube-ngram.pig that looks like this:
0,,0,1234
0,,1,1235
0,,2,1236

Generates a file with one line that looks like this:
1234,1235,1236
'''

import sys
from itertools import *
from collections import defaultdict

n = 256
d = 8

new = defaultdict(int)

for line in open(sys.argv[1], 'rb'):
    bits = line.strip().split(',')
    a = int(bits[2])
    v = int(bits[3])

    x = a % n
    y = (a % (n ** 2) - x) / n
    z = (a % (n ** 3) - x - y * n) / (n ** 2)

    xx = x / d
    yy = y / d
    zz = z / d

    new['%i,%i,%i' % (xx, yy, zz)] += v

o = []
for x, y, z in product(xrange(n), repeat=3):
    o.append(str(new['%i,%i,%i' % (x, y, z)]))

print ','.join(o)

