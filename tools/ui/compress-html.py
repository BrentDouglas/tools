#!/usr/bin/env python3
# coding: utf-8
"""
Compress HTML in a TSS file
"""

import argparse
import re


# For stripping WS from the html templates
ws = re.compile('^\s+$')
leading = re.compile('^\s*(<\S+.*)\s*$')
trailing = re.compile('^\s*([^<]\S+.*(>|\S\s))\s*$')


def trim_ws(line):
    mw = ws.search(line)
    if mw is not None:
        return ''
    mw = leading.search(line)
    if mw is not None:
        line = mw.group(1)
    mw = trailing.search(line)
    if mw is not None:
        line = ' ' + mw.group(1)
    return line


def compress_html(infile, outfile):
    # Trim ws from any inline templates we find that span multiple lines
    with open(outfile, encoding='utf-8', mode='w') as fout:
        with open(infile, encoding='utf-8', mode='r') as fin:
            replacing = False
            for line in fin:
                sp = line.split('`')
                if replacing:
                    if len(sp) == 2:
                        replacing = False
                        line = trim_ws(sp[0]) + '`' + sp[1]
                    else:
                        line = trim_ws(line)
                else:
                    if len(sp) == 2:
                        replacing = True
                        line = sp[0] + '`' + trim_ws(sp[1])
                fout.write(line)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', dest='fin', nargs='?', default=False, help='Infile')
    parser.add_argument('-o', dest='fout', nargs='?', default=False, help='Outfile')
    args = parser.parse_args()

    compress_html(args.fin, args.fout)


if __name__ == '__main__':
    main()
