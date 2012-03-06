#!/usr/bin/env python

import markdown

html = markdown.markdown(open('README.md').read())
open('README.html', 'wb').write(html)

