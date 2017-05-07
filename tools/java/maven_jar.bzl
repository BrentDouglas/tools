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

GERRIT = "GERRIT:"

GERRIT_API = "GERRIT_API:"

MAVEN_CENTRAL = "MAVEN_CENTRAL:"

MAVEN_LOCAL = "MAVEN_LOCAL:"

def _maven_release(ctx, pkg):
  """induce file and url name from maven package."""
  file_version = pkg.version if not pkg.classifier else pkg.version + '-' + pkg.classifier

  file = pkg.artifact_id.lower() + '-' + file_version
  url = '/'.join([
    ctx.attr.repository,
    pkg.group_id.replace('.', '/'),
    pkg.artifact_id,
    pkg.version,
    pkg.artifact_id + '-' + file_version])

  return file, url

# Creates a struct containing the different parts of an artifact's FQN
def _create_coordinates(fully_qualified_name):
  parts = fully_qualified_name.split(":")
  packaging = "jar"
  classifier = None

  if len(parts) == 3:
    group_id, artifact_id, version = parts
  elif len(parts) == 4:
    group_id, artifact_id, version, packaging = parts
  elif len(parts) == 5:
    group_id, artifact_id, version, packaging, classifier = parts
  else:
    fail('Invalid fully qualified name for artifact: %s:\nexpected artifact="groupId:artifactId:version[:packaging][:classifier]"'
     % fully_qualified_name)

  return struct(
      fully_qualified_name = fully_qualified_name,
      group_id = group_id,
      artifact_id = artifact_id,
      packaging = packaging,
      classifier = classifier,
      version = version,
  )

def _format_deps(attr, deps):
  formatted_deps = ""
  if deps:
    if len(deps) == 1:
      formatted_deps += "%s = [\'%s\']," % (attr, deps[0])
    else:
      formatted_deps += "%s = [\n" % attr
      for dep in deps:
        formatted_deps += "        \'%s\',\n" % dep
      formatted_deps += "    ],"
  return formatted_deps

def _generate_jar_build_file(ctx, binjar, srcjar, packaging):
  srcjar_attr = ""
  if srcjar:
    srcjar_attr = 'srcjar = "%s",' % srcjar
  contents = """
# DO NOT EDIT: automatically generated BUILD file for maven_jar rule {rule_name}
package(default_visibility = ["//visibility:public"])
java_import(
    name = "{packaging}",
    jars = ["{binjar}"],
    {srcjar_attr}
    {deps}
    {exports}
)
java_import(
    name = "neverlink",
    jars = ["{binjar}"],
    neverlink = 1,
    {deps}
    {exports}
)
\n""".format(srcjar_attr = srcjar_attr,
              rule_name = ctx.name,
              binjar = binjar,
              packaging = packaging,
              deps = _format_deps("deps", ctx.attr.deps),
              exports = _format_deps("exports", ctx.attr.exports))
  if srcjar:
    contents += """
java_import(
    name = "src",
    jars = ["{srcjar}"],
)
""".format(srcjar = srcjar)
  ctx.file('%s/BUILD.bazel' % ctx.path(packaging), contents, False)

def _generate_other_build_file(ctx, binfile, packaging):
  contents = """
# DO NOT EDIT: automatically generated BUILD file for maven_jar rule {rule_name}
package(default_visibility = ['//visibility:public'])
filegroup(
    name = "{packaging}",
    srcs = ["{binfile}"],
)
\n""".format(
    rule_name = ctx.name,
    binfile = binfile,
    packaging = packaging,
)
  ctx.file('%s/BUILD.bazel' % ctx.path(packaging), contents, False)

def _maven_jar_impl(ctx):
  """rule to download a Maven archive."""
  pkg = _create_coordinates(ctx.attr.artifact)
  name = ctx.name
  sha1 = ctx.attr.sha1

  file, url = _maven_release(ctx, pkg)

  binjar = file + '.' + pkg.packaging
  binjar_path = ctx.path('/'.join([pkg.packaging, binjar]))
  binurl = url + '.' + pkg.packaging

  # IDEA doesn't get the real env
  python = ctx.which("python3")
  if python == None:
    python = "/usr/local/bin/python3"
  script = ctx.path(ctx.attr._download_script)

  args = [python, script, "-o", binjar_path, "-u", binurl]
  if ctx.attr.sha1:
    args.extend(["-v", sha1])
  if ctx.attr.unsign:
    args.append('--unsign')
  for x in ctx.attr.exclude:
    args.extend(['-x', x])

  out = ctx.execute(args)

  if out.return_code:
    fail("failed %s: %s" % (' '.join(args), out.stderr))

  srcjar = None
  if ctx.attr.src_sha1 or ctx.attr.attach_source:
    srcjar = file + '-src.jar'
    srcurl = url + '-' + ctx.attr.src_name + '.jar'
    srcjar_path = ctx.path('jar/' + srcjar)
    args = [python, script, "-o", srcjar_path, "-u", srcurl]
    if ctx.attr.src_sha1:
      args.extend(['-v', ctx.attr.src_sha1])
    out = ctx.execute(args)
    if out.return_code:
      fail("failed %s: %s" % (args, out.stderr))

  if pkg.packaging == 'jar':
    _generate_jar_build_file(ctx, binjar, srcjar, pkg.packaging)
  else:
    _generate_other_build_file(ctx, binjar, pkg.packaging)


maven_jar = repository_rule(
    attrs = {
        "artifact": attr.string(mandatory = True),
        "sha1": attr.string(),
        "src_sha1": attr.string(),
        "src_name": attr.string(default = "sources"),
        "_download_script": attr.label(default = Label("//tools/java:download_file.py")),
        "repository": attr.string(default = MAVEN_CENTRAL),
        "attach_source": attr.bool(default = True),
        "unsign": attr.bool(default = False),
        "deps": attr.string_list(),
        "exports": attr.string_list(),
        "exclude": attr.string_list(),
    },
    local = True,
    implementation = _maven_jar_impl,
)
