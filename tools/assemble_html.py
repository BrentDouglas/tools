#!/usr/bin/env python3
# coding: utf-8
"""
Take the SHA-1 of a JS, CSS file, append it to the filename
and insert then into the HTML file.
"""

import getopt
import hashlib
import os
import shutil
import sys


def usage():
    print("""
Usage: assemble_html.py opts...

    [-H|--hash]     If the hash should be appended
    [-D|--out_dir]  Output dir for HTML, JS and CSS files
    [-j|--js_file]  Javascript file
    [-c|--css_file] CSS file
    [-i|--html_in]  The input HTML file
    [-o|--html_out] The output HTML file
    [-h|--help]     Print this message and exit
""")


hash_names = False
out_dir = None
css_dir = None
js_dir = None
js_files = []
css_files = []
html_in = None
html_out = None

try:
    opts, args = getopt.getopt(
        sys.argv[1:],
        "HD:j:c:i:o:h",
        ["hash", "out_dir=", "js_file=", "css_file=", "html_in=", "html_out=", "help"]
    )
except getopt.GetoptError as err:
    print(str(err))
    usage()
    sys.exit(2)
for o, a in opts:
    if o in ("-H", "--hash"):
        hash_names = True
    elif o in ("-D", "--out_dir"):
        out_dir = a
    elif o in ("-j", "--js_file"):
        js_files.append(a)
    elif o in ("-c", "--css_file"):
        css_files.append(a)
    elif o in ("-i", "--html_in"):
        html_in = a
    elif o in ("-o", "--html_out"):
        html_out = a
    elif o in ("-h", "--help"):
        usage()
        sys.exit()
    else:
        assert False, "unhandled option " + o

scripts = ''
for js_file in js_files:
    with open(js_file, encoding='utf-8', mode='r') as fin:
        js_name = os.path.basename(js_file)
        if not hash_names:
            js_out = js_name
        else:
            sha = hashlib.sha1()
            sha.update(fin.read().encode('utf-8'))
            js_sum = sha.hexdigest()[0:8]
            js_out = js_name[:-3] + '.' + js_sum + '.js'
        js_out = 'js/%s' % js_out
        if scripts:
            scripts += '"></script><script src="%s' % js_out
        else:
            scripts += js_out
        os.makedirs(os.path.join(out_dir, 'js'))
        out_file = out_dir + js_out
        if js_file != out_file:
            shutil.copy(js_file, out_file)

styles = ''
for css_file in css_files:
    with open(css_file, encoding='utf-8', mode='r') as fin:
        css_name = os.path.basename(css_file)
        if not hash_names:
            css_out = css_name
        else:
            sha = hashlib.sha1()
            sha.update(fin.read().encode('utf-8'))
            css_sum = sha.hexdigest()[0:8]
            css_out = css_name[:-4] + '.' + css_sum + '.css'
        css_out = 'css/%s' % css_out
        if styles:
            styles += '"><link rel="stylesheet" href="%s' % css_out
        else:
            styles += css_out
        os.makedirs(os.path.join(out_dir, 'css'))
        out_file = out_dir + css_out
        if css_file != out_file:
            shutil.copy(css_file, out_file)

with open(html_in, encoding='utf-8', mode='r') as fin:
    with open(html_out, encoding='utf-8', mode='w') as fout:
        for line in fin:
            line = line.replace('CSS_FILE', styles)
            line = line.replace('JS_FILE', scripts)
            fout.write(line.encode('utf-8', 'replace').decode())
