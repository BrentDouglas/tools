
load("//tools:util.bzl", "join_list", "join_dict", "get_path", "is_any_jar")

def _download_npm(ctx, name, version, deps, rebuild, types=False):
    repository = ctx.attr.repository
    file_name = name.replace('@', 'at-').replace('/', '-')
    if types:
        pkg = '@types/%s@%s' % (name, version)
        file = '%s-types-%s.jar' % (file_name, version)
    else:
        pkg = '%s@%s' % (name, version)
        file = '%s-%s.jar' % (file_name, version)
    script = ctx.path(ctx.attr._download_script)
    os = ctx.os.name
    node = ctx.path(ctx.attr._node)
    npm = ctx.path(ctx.attr._npm)
    dep_str = ""
    if deps:
        for k in deps:
            dep_str += " -d '%s@%s'" % (k, deps[k])
    out_file = ctx.path("pkg/%s" % file)
    cmd = " \\\n  && ".join([
      "export PATH",
      "p=$PWD",
      "mkdir -p $(dirname %s)" % out_file,
      "NODE=%s NPM=%s OS=%s %s -f '%s' -p '%s' %s -r '%s' -o '%s'" % (node, npm, os, script, file, pkg, dep_str, repository, out_file),
    ])
    out = ctx.execute([ctx.which("bash"), "-c", cmd])
    return struct(
        out = out,
        file = file,
    )


def _npm_archive_impl(ctx):
    name = ctx.name if not ctx.attr.package else ctx.attr.package
    version = ctx.attr.version
    main = _download_npm(ctx, name, version, ctx.attr.deps, ctx.attr.rebuild)
    if main.out.return_code:
        fail("Can't fetch %s@%s: %s" % (name, version, main.out.stderr))

    types = None
    if ctx.attr.types:
        types_name = name if not ctx.attr.types_package else ctx.attr.types_package
        types_version = version if not ctx.attr.types_version else ctx.attr.types_version
        types = _download_npm(ctx, types_name, types_version, ctx.attr.types_deps, ctx.attr.rebuild, True)
        if types.out.return_code:
            fail("Can't fetch types for %s@%s: %s\n" % (types_name, types_version, types.out.stderr) +
                 "You can avoid this message by setting `types = False`")

    main_content = """
java_import(
    name = "pkg",
    jars = ["%s"],
    srcjar = "%s",
)""" % (main.file, main.file)

    types_content = """
java_import(
    name = "types",
    jars = ["%s"],
    srcjar = "%s",
)""" % (types.file, types.file) if ctx.attr.types and not types.out.return_code else ""

    return ctx.file(
        "%s/BUILD.bazel" % ctx.path("pkg"),
        "\n".join([
            """package(default_visibility = ["//visibility:public"])""",
            main_content,
            types_content,
        ]),
        False
    )

npm_archive = repository_rule(
    implementation = _npm_archive_impl,
    local = True,
    attrs = {
        "_download_script": attr.label(default = Label("//tools/ui:download-npm")),
        "_node": attr.label(default = Label("@nodejs//:bin/node")),
        "_npm": attr.label(default = Label("@nodejs//:bin/npm")),
        "repository": attr.string(default = "http://registry.npmjs.org"),
        "package": attr.string(mandatory = False),
        "version": attr.string(),
        "deps": attr.string_dict(),
        "types": attr.bool(default = True),
        "types_version": attr.string(),
        "types_package": attr.string(mandatory = False),
        "types_deps": attr.string_dict(),
        "rebuild": attr.bool(default = False),
    },
)
"""Download a NPM archive. If we can we will also download the type files.
"""


def _npm_filegroup_impl(ctx):
    label = ctx.attr.archive.label
    name = label.workspace_root[9:] # external/<name>
    base = ctx.bin_dir.path
    dest_dir = base + "/" + ctx.label.package
    outputs = []
    moves = []
    for x in ctx.attr.include:
        out = ctx.actions.declare_file(ctx.attr.include[x])
        outputs.append(out)
        moves.append("cp %s $p/%s" % (x, out.path))
    cmd = " \\\n  && ".join([
      "export PATH",
      "p=$PWD",
      "rm -rf %s" % (dest_dir),
      "mkdir -p %s" % (dest_dir),
      "cd %s" % (dest_dir),
      "jar xf $p/%s" % (ctx.file.archive.path),
    ] + moves)
    ctx.actions.run_shell(
        inputs=[ctx.file.archive],
        outputs=outputs,
        command=cmd
    )
    return struct(
        files = depset(outputs),
    )

npm_filegroup = rule(
    implementation = _npm_filegroup_impl,
    attrs = {
        "archive": attr.label(allow_single_file = [
            ".jar",
            ".srcjar",
        ]),
        "include": attr.string_dict(),
    },
)
"""Extract a filegroup from within an NPM archive. This
is for when we want to use this files in the final archive.
"""


def _npm_combine_impl(ctx):
    base = ctx.bin_dir.path
    dest_dir = base + "/" + ctx.label.package + "/" + ctx.label.name
    moves = []
    for dep in ctx.attr.deps:
      label = dep.label
      for x in dep.files.to_list():
        if is_any_jar(x.path):
          moves.append("jar xf $p/%s" % x.path)
        else:
          moves.append("tar zxf $p/%s" % x.path)
    cmd = " \\\n  && ".join([
      "export PATH",
      "p=$PWD",
      "rm -rf %s" % (dest_dir),
      "mkdir -p %s" % (dest_dir),
      "cd %s" % (dest_dir),
    ] + moves + [
      "jar cfM $p/%s ." % (ctx.outputs.dest.path),
    ])
    ctx.actions.run_shell(
        inputs = ctx.files.deps,
        outputs = [ctx.outputs.dest],
        command = cmd
    )
    return struct(
        files = depset([ctx.outputs.dest]),
    )

npm_combine = rule(
    implementation = _npm_combine_impl,
    attrs = {
        "deps": attr.label_list(),
    },
    outputs = {
        "dest": "%{name}.jar"
    }
)
"""Combine a set of NPM archives into one. Used to sync IDEA with the actual dependencies.
"""


def _npm_package_impl(ctx):
    name = ctx.label.name
    package_name = name if not ctx.attr.package_name else ctx.attr.package_name
    pkg = None
    if ctx.attr.package:
        pkg = ctx.file.package
    else:
        pkg = ctx.actions.declare_file(package_name + "/package.json")
        ctx.actions.write(
            pkg,
            "{\n" + join_list("    ", [
               '"name": "%s"' % package_name,
               '"version": "%s"' % ctx.attr.version,
               '' if not ctx.attr.keywords else '"keywords": "%s"' % ctx.attr.keywords,
               '' if not ctx.attr.homepage else '"homepage": "%s"' % ctx.attr.homepage,
               '' if not ctx.attr.bugs else '"bugs": "%s"' % ctx.attr.bugs,
               '' if not ctx.attr.description else '"description": "%s"' % ctx.attr.description,
               '' if not ctx.attr.main else '"main": "%s"' % ctx.attr.main,
               '' if not ctx.attr.types else '"types": "%s"' % ctx.attr.types,
               '' if not ctx.attr.bin else '"bin": {\n%s    \n}' % join_dict("        ", ctx.attr.bin),
               '"license": "%s"' % ctx.attr.license,
               '' if not ctx.attr.man else '"man": [\n%s    \n]' % join_list("        ", ctx.attr.man),
               '' if not ctx.attr.repository else '"repository": {\n%s    \n}' % join_dict("        ", ctx.attr.repository),
               '' if not ctx.attr.dependencies else '"dependencies": {\n%s    \n}' % join_dict("        ", ctx.attr.dependencies),
               '' if not ctx.attr.dev_dependencies else '"devDependencies": {\n%s    \n}' % join_dict("        ", ctx.attr.dev_dependencies),
               '' if not ctx.attr.peer_dependencies else '"peerDependencies": {\n%s    \n}' % join_dict("        ", ctx.attr.peer_dependencies),
               '' if not ctx.attr.bundled_dependencies else '"bundledDependencies": {\n%s    \n}' % join_dict("        ", ctx.attr.bundled_dependencies),
               '' if not ctx.attr.optional_dependencies else '"optionalDependencies": {\n%s    \n}' % join_dict("        ", ctx.attr.optional_dependencies),
               '' if not ctx.attr.engines else '"engines": {\n%s    \n}' % join_dict("        ", ctx.attr.engines),
               '' if not ctx.attr.os else '"os": [\n%s    \n]' % join_list("        ", ctx.attr.os),
               '' if not ctx.attr.cpu else '"cpu": [\n%s    \n]' % join_list("        ", ctx.attr.cpu),
               '"preferGlobal": %s' % ('true' if ctx.attr.prefer_global else 'false'),
               '"private": %s' % ('true' if ctx.attr.private else 'false'),
               '' if not ctx.attr.publish_config else '"publishConfig": {\n%s    \n}' % join_dict("        ", ctx.attr.publish_config),
            ]) + "\n}",
            False
        )
    if package_name.startswith('@types/'):
        tar_dir = '@types/'
        out = ctx.actions.declare_file(package_name.replace(tar_dir, "") + "-types.tgz")
    else:
        tar_dir = package_name
        out = ctx.actions.declare_file(package_name + ".tgz")
    mvs = []
    for attr in ctx.attr.srcs:
      for file in attr.files:
        path = get_path(ctx, attr, file)
        mvs.append("mkdir -p $(dirname $p/%s/%s)" % (package_name, path))
        mvs.append("cp %s $p/%s/%s" % (file.path, package_name, path))
    cmd = " \\\n  && ".join([
      "export PATH",
      "p=$PWD",
      ] + mvs + [
      "cp %s $p/%s" % (pkg.path, package_name),
      "mkdir -p $(dirname %s)" % (out.path),
      'if [ $(uname) == "Darwin" ] ; then export TAR_LINK_OPT="L" else export TAR_LINK_OPT="H"; fi',
      "tar cfz${TAR_LINK_OPT} - ./%s > %s" % (tar_dir, out.path),
    ])
    cmd_file = ctx.actions.declare_file(ctx.label.name + "-npm-pkg-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd
    )
    outs = [out]
    ctx.actions.run_shell(
        inputs = [pkg, cmd_file] + ctx.files.srcs,
        outputs = outs,
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outs))

npm_package = rule(
    implementation = _npm_package_impl,
    attrs = {
        "types_only": attr.bool(default = False),
        "srcs": attr.label_list(allow_files = True),
        "package": attr.label(allow_single_file = True),
        "package_name": attr.string(),
        "version": attr.string(mandatory = True),
        "keywords": attr.string(),
        "homepage": attr.string(),
        "bugs": attr.string(),
        "description": attr.string(),
        "license": attr.string(default = "UNLICENSED"),
        "main": attr.string(),
        "types": attr.string(),
        "bin": attr.string_dict(),
        "man": attr.string_list(),
        "repository": attr.string_dict(),
        "dependencies": attr.string_dict(),
        "dev_dependencies": attr.string_dict(),
        "peer_dependencies": attr.string_dict(),
        "bundled_dependencies": attr.string_dict(),
        "optional_dependencies": attr.string_dict(),
        "engines": attr.string_dict(),
        "os": attr.string_list(),
        "cpu": attr.string_list(),
        "prefer_global": attr.bool(default = False),
        "private": attr.bool(default = True),
        "publish_config": attr.string_dict(),
    },
)
"""Build an npm package from the provided files.

All the properties not listed are fields of package.json, refer
to the NPM documentation for what they do. They are all ignored
if the "package" file is supplied.

Args:
  types_only: If true this package will be created with an @types prefix
  srcs: The files that will be bundled in this module
  package: The package.json file to include in the module
  package_name: The "name" attribute of package.json, if its not provided it will
    use the name of the label.
"""