#!/usr/bin/env python3
# Copyright (C) 2013 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from hashlib import sha1
from optparse import OptionParser
from os import link, makedirs, path, remove
import shutil
from subprocess import check_call, CalledProcessError
from sys import stderr
from zipfile import ZipFile, BadZipfile, LargeZipFile

GERRIT_HOME = path.expanduser('~/.gerritcodereview')
# TODO(davido): Rename in bazel-cache
CACHE_DIR = path.join(GERRIT_HOME, 'buck-cache', 'downloaded-artifacts')
LOCAL_PROPERTIES = 'local.properties'
REPO_ROOTS = {
  'GERRIT': 'http://gerrit-maven.storage.googleapis.com',
  'GERRIT_API': 'https://gerrit-api.commondatastorage.googleapis.com/release',
  'MAVEN_CENTRAL': 'http://repo1.maven.org/maven2',
  'MAVEN_LOCAL': 'file://' + path.expanduser('~/.m2/repository'),
  'MAVEN_SNAPSHOT': 'https://oss.sonatype.org/content/repositories/snapshots',
}


def resolve_url(url, redirects):
  """ Resolve URL of a Maven artifact.

  prefix:path is passed as URL. prefix identifies known or custom
  repositories that can be rewritten in redirects set, passed as
  second arguments.

  A special case is supported, when prefix neither exists in
  REPO_ROOTS, no in redirects set: the url is returned as is.
  This enables plugins to pass custom maven_repository URL as is
  directly to maven_jar().

  Returns a resolved path for Maven artifact.
  """
  s = url.find(':')
  if s < 0:
    return url
  scheme, rest = url[:s], url[s+1:]
  if scheme in redirects:
    root = redirects[scheme]
  elif scheme in REPO_ROOTS:
    root = REPO_ROOTS[scheme]
  else:
    return url
  root = root.rstrip('/')
  rest = rest.lstrip('/')
  return '/'.join([root, rest])


def hash_file(hash_obj, path):
  """Hash the contents of a file.

  Args:
    hash_obj: an open hash object, e.g. hashlib.sha1().
    path: path to the file to hash.

  Returns:
    The passed-in hash_obj.
  """
  with open(path, 'rb') as f:
    while True:
      b = f.read(8192)
      if not b:
        break
      hash_obj.update(b)
  return hash_obj


def safe_mkdirs(d):
  if path.isdir(d):
    return
  try:
    makedirs(d)
  except OSError as err:
    if not path.isdir(d):
      raise err


def download_properties(root_dir):
  """ Get the download properties.

  First tries to find the properties file in the given root directory,
  and if not found there, tries in the Gerrit settings folder in the
  user's home directory.

  Returns a set of download properties, which may be empty.

  """
  p = {}
  local_prop = path.join(root_dir, LOCAL_PROPERTIES)
  if not path.isfile(local_prop):
    local_prop = path.join(GERRIT_HOME, LOCAL_PROPERTIES)
  if path.isfile(local_prop):
    try:
      with open(local_prop) as fd:
        for line in fd:
          if line.startswith('download.'):
            d = [e.strip() for e in line.split('=', 1)]
            name, url = d[0], d[1]
            p[name[len('download.'):]] = url
    except OSError:
      pass
  return p


def cache_entry(args):
  if args.v:
    h = args.v
  else:
    h = sha1(args.u.encode('utf-8')).hexdigest()
  name = '%s-%s' % (path.basename(args.o), h)
  return path.join(CACHE_DIR, name)

opts = OptionParser()
opts.add_option('-o', help='local output file')
opts.add_option('-u', help='URL to download')
opts.add_option('-v', help='expected content SHA-1')
opts.add_option('-x', action='append', help='file to delete from ZIP')
opts.add_option('--exclude_java_sources', action='store_true')
opts.add_option('--unsign', action='store_true')
args, _ = opts.parse_args()

root_dir = args.o
while root_dir and root_dir != "/":
  root_dir, n = path.split(root_dir)
  if n == 'WORKSPACE':
    break

redirects = download_properties(root_dir)
cache_ent = cache_entry(args)
src_url = resolve_url(args.u, redirects)

if not path.exists(cache_ent):
  try:
    safe_mkdirs(path.dirname(cache_ent))
  except OSError as err:
    print('error creating directory %s: %s' %
          (path.dirname(cache_ent), err), file=stderr)
    exit(1)

  print('Download %s' % src_url, file=stderr)
  try:
    check_call(['curl', '--proxy-anyauth', '-ksSfLo', cache_ent, src_url])
  except OSError as err:
    print('could not invoke curl: %s\nis curl installed?' % err, file=stderr)
    exit(1)
  except CalledProcessError as err:
    print('error using curl: %s' % err, file=stderr)
    exit(1)

if args.v:
  have = hash_file(sha1(), cache_ent).hexdigest()
  if args.v != have:
    print((
      '%s:\n' +
      'expected %s\n' +
      'received %s\n') % (src_url, args.v, have), file=stderr)
    try:
      remove(cache_ent)
    except OSError as err:
      if path.exists(cache_ent):
        print('error removing %s: %s' % (cache_ent, err), file=stderr)
    exit(1)

exclude = []
if args.x:
  exclude += args.x
if args.exclude_java_sources:
  try:
    with ZipFile(cache_ent, 'r') as zf:
      for n in zf.namelist():
        if n.endswith('.java'):
          exclude.append(n)
  except (BadZipfile, LargeZipFile) as err:
    print('error opening %s: %s' % (cache_ent, err), file=stderr)
    exit(1)

if args.unsign:
  try:
    with ZipFile(cache_ent, 'r') as zf:
      for n in zf.namelist():
        if (n.endswith('.RSA')
            or n.endswith('.SF')
            or n.endswith('.LIST')):
          exclude.append(n)
  except (BadZipfile, LargeZipFile) as err:
    print('error opening %s: %s' % (cache_ent, err), file=stderr)
    exit(1)

safe_mkdirs(path.dirname(args.o))
if exclude:
  try:
    shutil.copyfile(cache_ent, args.o)
  except (shutil.Error, IOError) as err:
    print('error copying to %s: %s' % (args.o, err), file=stderr)
    exit(1)
  try:
    check_call(['zip', '-d', args.o] + exclude)
  except CalledProcessError as err:
    print('error removing files from zip: %s' % err, file=stderr)
    exit(1)
else:
  try:
    link(cache_ent, args.o)
  except OSError as err:
    try:
      shutil.copyfile(cache_ent, args.o)
    except (shutil.Error, IOError) as err:
      print('error copying to %s: %s' % (args.o, err), file=stderr)
      exit(1)