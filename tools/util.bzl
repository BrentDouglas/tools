"""Utilities that are applicable in multiple areas"""

ANSI_MAGENTA = "\033[35m"
ANSI_CYAN = "\033[36m"
ANSI_WHITE = "\033[37m"
ANSI_RESET = "\033[00m"

def is_archive(path):
    return is_zip(path) or is_jar(path) or is_tar(path)

def is_zip(path):
    return path.endswith(".zip")

def is_any_jar(path):
    return is_jar(path) or is_srcjar(path)

def is_jar(path):
    return path.endswith(".jar")

def is_srcjar(path):
    return path.endswith(".srcjar")

def is_any_tar(path):
    return is_tgz(path) or is_tbz(path) or is_tar(path)

def is_tar(path):
    return path.endswith(".tar")

def is_tgz(path):
    return path.endswith(".tgz") or path.endswith(".tar.gz")

def is_tbz(path):
    return path.endswith(".tar.bz2") or path.endswith(".tar.bzip2")

def list_file(path, sep):
    return sep.join([
        "jar tf %s" % (path) if is_jar(path) else "cat %s | tar tf -" % (path),
    ]) + sep

def extract_file(path):
    return " \\\n  && ".join([
        "jar xf %s" % (path) if is_jar(path) else "cat %s | tar xf -" % (path),
    ])

def join_list(prefix, list):
    n = len(list)
    ret = ""
    for i in range(0, n):
        it = list[i]
        if not it:
            continue
        if ret:
            ret += ","
        if i != 0:
            ret += "\n"
        ret += prefix + it
    return ret

def join_dict(prefix, dict):
    n = len(dict)
    ret = ""
    i = 0
    for k in dict:
        v = dict[k]
        if ret:
            ret += ","
        if i != 0:
            ret += "\n"
        ret += prefix + '"%s": "%s"' % (k, v)
        i += 1
    return ret

def strip_base(path, *args):
    for base in args:
        path = path if not path.startswith(base) else path[len(base) + 1:]
    return path

def get_path(ctx, attr, file):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    pkg = attr.label.package
    return strip_base(file.path, base, gen_base, pkg)

def get_path_of(ctx, attr, path):
    base = ctx.bin_dir.path
    pkg = attr.label.package
    if path.startswith(base + "/" + pkg):
        return path[len(base + "/" + pkg) + 1:]
    if path.startswith(base):
        return path[len(base) + 1:]
    if path.startswith(pkg):
        return path[len(pkg) + 1:]
    return path

def get_debug_commands(ctx, *args):
    """Generate commands to print information about the execution environment of a rule

    Args:
      ctx: The context object
      args: A list of configuration files to print out
    """
    label = "//" + ctx.label.package + ":" + ctx.label.name
    ret = [
        'echo -e "%sDEBUG: Start rule%s %s%s%s %s"' % (ANSI_MAGENTA, ANSI_RESET, ANSI_CYAN, label, ANSI_RESET, ANSI_RESET),
        'echo -e "%sThe sandbox contains these files:%s"' % (ANSI_WHITE, ANSI_RESET),
        "find . -not -type d | grep -v node_modules",
        'echo -en "%s"' % ANSI_RESET,
    ]
    for cfg in args:
        ret.append('echo -e "%sThe config file %s%s%s %scontains:%s"' % (ANSI_WHITE, ANSI_MAGENTA, cfg, ANSI_RESET, ANSI_WHITE, ANSI_RESET))
        ret.append("cat %s" % cfg)
        ret.append('echo -en "%s"' % ANSI_RESET)
    ret.append('echo -e "%sDEBUG: End rule%s %s%s%s %s"' % (ANSI_MAGENTA, ANSI_RESET, ANSI_CYAN, label, ANSI_RESET, ANSI_RESET))
    return ret

def get_post_debug_commands(ctx):
    """Generate commands to print information about the execution environment of a rule

    Args:
      ctx: The context object
      args: A list of configuration files to print out
    """
    label = "//" + ctx.label.package + ":" + ctx.label.name
    ret = [
        'echo -e "%sDEBUG: Start post rule%s %s%s%s %s"' % (ANSI_MAGENTA, ANSI_RESET, ANSI_CYAN, label, ANSI_RESET, ANSI_RESET),
        'echo -e "%sAfter execution the sandbox contains these files:%s"' % (ANSI_WHITE, ANSI_RESET),
        "find . -not -type d | grep -v node_modules",
        'echo -en "%s"' % ANSI_RESET,
    ]
    ret.append('echo -e "%sDEBUG: End post rule%s %s%s%s %s"' % (ANSI_MAGENTA, ANSI_RESET, ANSI_CYAN, label, ANSI_RESET, ANSI_RESET))
    return ret

def _template_file_impl(ctx):
    ctx.template_action(
        template = ctx.file.src,
        output = ctx.outputs.out,
        substitutions = ctx.attr.substitutions,
    )

template_file = rule(
    implementation = _template_file_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            allow_files = True,
            single_file = True,
        ),
        "substitutions": attr.string_dict(mandatory = True),
        "out": attr.output(mandatory = True),
    },
)

def _move_impl(ctx):
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        "mkdir -p %s" % ctx.outputs.dest.dirname,
        "cp %s %s" % (ctx.file.src.path, ctx.outputs.dest.path),
    ])
    ctx.action(
        inputs = [ctx.file.src],
        outputs = [ctx.outputs.dest],
        command = cmd,
    )
    return struct(
        files = depset([ctx.outputs.dest]),
    )

move = rule(
    implementation = _move_impl,
    attrs = {
        "src": attr.label(allow_single_file = True),
        "dest": attr.output(),
    },
)
"""Move a file.

Args:
  src: The input file
  dest: The output location to move the file to
"""

def _move_up_impl(ctx):
    """
    Move a set of files up some dirs.
    """
    dirs = ctx.attr.dirs
    dirs = dirs if dirs.endswith("/") else dirs + "/"
    moves = []
    outs = []
    for i in range(0, len(ctx.attr.srcs)):
        attr = ctx.attr.srcs[i]
        for file in attr.files:
            path = get_path(ctx, attr, file)
            out = ctx.new_file(path[len(dirs):])
            outs.append(out)
            moves += [
                "mkdir -p %s" % out.dirname,
                "cp %s %s" % (file.path, out.path),
            ]
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
    ] + moves)
    ctx.action(
        inputs = ctx.files.srcs,
        outputs = outs,
        command = cmd,
    )
    return struct(
        files = depset(outs),
    )

move_up = rule(
    implementation = _move_up_impl,
#    doc = "Move a set of files up some dirs.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "The input files.",
        ),
        "dirs": attr.string(
            doc = "The directories to move the files up",
        ),
    },
)
"""Move a set of files up some dirs.

Args:
  srcs: The input files
  dirs: The directories to move the files up
"""

def _move_down_impl(ctx):
    dirs = ctx.attr.dirs
    dirs = dirs if dirs.endswith("/") else dirs + "/"
    moves = []
    outs = []
    for i in range(0, len(ctx.attr.srcs)):
        attr = ctx.attr.srcs[i]
        for file in attr.files:
            path = get_path(ctx, attr, file)
            out = ctx.new_file(dirs + path)
            outs.append(out)
            moves += [
                "mkdir -p %s" % out.dirname,
                "cp %s %s" % (file.path, out.path),
            ]
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
    ] + moves)
    ctx.action(
        inputs = ctx.files.srcs,
        outputs = outs,
        command = cmd,
    )
    return struct(
        files = depset(outs),
    )

move_down = rule(
    implementation = _move_down_impl,
#    doc = "Move a set of files down some dirs.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "The input files",
        ),
        "dirs": attr.string(
            doc = "The directories to move the files down into",
        ),
    },
)
"""Move a set of files down some dirs.

Args:
  srcs: The input files
  dirs: The directories to move the files down into
"""

def filter_filetypes(types, srcs):
    ret = []
    for src in srcs:
        for type in types:
            if src.basename.endswith(type):
                ret.append(src)
                break
    return ret

def _filter_impl(ctx):
    srcs = ctx.files.srcs
    outs = filter_filetypes(ctx.attr.types, srcs)
    return struct(
        files = depset(outs),
    )

filter = rule(
    implementation = _filter_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "types": attr.string_list(),
    },
)
"""Filter a list of files by type.

Args:
  srcs: The input files
  types: A list of file types to return
"""

def _find_impl(ctx):
    target = ctx.attr.file
    files = "\n"
    for src in ctx.attr.srcs:
        for file in src.files:
            path = get_path(ctx, src, file)
            if path == target if ctx.attr.path else file.basename == target:
                return struct(
                    files = depset([file]),
                )
            else:
                files += "\n" + path if ctx.attr.path else file.basename
    fail("No file with name %s. Found:%s" % (ctx.attr.file, files))

find = rule(
    implementation = _find_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "file": attr.string(),
        "path": attr.bool(default = False),
    },
)
"""Return a named file from another rule.

Args:
  srcs: The files to filter
  file: The files basename or path to search for in the src files
  path: If true, the file argument needs to match the files basename
    if false it needs to match the files path
"""

def _find_all_impl(ctx):
    target = ctx.attr.file
    files = "\n"
    ret = []
    for file in ctx.files.srcs:
        if file.basename == target:
            ret.append(file)
        else:
            files += "\n" + file.basename
    if ret:
        return struct(
            files = depset(ret),
        )
    fail("No file with name %s. Found:%s" % (ctx.attr.file, files))

find_all = rule(
    implementation = _find_all_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "file": attr.string(),
    },
)
"""Return all files with a name from another rule.

Args:
  srcs: The files to filter
  file: The filename to search for in the src files
"""

def _exclude_impl(ctx):
    files = []
    for src in ctx.files.srcs:
        if src.path.find(ctx.attr.value) == -1:
            files.append(src)
    return struct(
        files = depset(files),
    )

exclude = rule(
    implementation = _exclude_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "value": attr.string(),
    },
)
"""Filter the files that match a substring.

Args:
  srcs: The files to filter
  value: The value to search for in the src files name
"""

def _dirname_impl(ctx):
    outputs = []
    for i in range(0, len(ctx.attr.srcs)):
        attr = ctx.attr.srcs[i]
        for file in attr.files:
            path = get_path(ctx, attr, file)
            out = ctx.new_file(path)
            outputs.append(out)
            ctx.template_action(
                template = file,
                output = out,
                substitutions = {
                    "{{__dirname}}": ctx.attr.src_prefix + path[:path.rindex("/")],
                },
            )
    return struct(
        files = depset(outputs),
    )

dirname = rule(
    implementation = _dirname_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "src_prefix": attr.string(),
    },
)
"""Replace {{__dirname}} with the directory.

Args:
  srcs: The files to be templated
  src_prefix: A prefix that can be added to the relative working directory
    when replacing the token.
"""

def _template_content_impl(ctx):
    template = ctx.file.template
    data = ctx.file.data
    output = ctx.outputs.dest

    cmd = "\n".join([
        "#!/usr/bin/env bash",
        "set -euf -o pipefail",
        "export PATH",
        "p=$PWD",
        """CONTENT="$(cat %s)" """ % template.path,
        """echo "${CONTENT/%s/$(cat %s)}" > %s""" % (ctx.attr.token, data.path, output.path),
    ])
    ctx.action(
        inputs = [template, data],
        outputs = [output],
        command = cmd,
    )
    return struct(
        files = depset([output]),
    )

template_content = rule(
    implementation = _template_content_impl,
    attrs = {
        "template": attr.label(allow_single_file = True),
        "data": attr.label(allow_single_file = True),
        "token": attr.string(),
        "dest": attr.output(),
    },
)
"""Replace a token in a file with the content from another file

Args:
  template: The template to use
  data: A file containing content to be inserted into the template
  token: The token to be replaced with the data file in the template
  dest: The output file
"""

def _base_64_impl(ctx):
    src = ctx.file.src
    output = ctx.outputs.dest

    cmd = "\n".join([
        "#!/usr/bin/env bash",
        "set -euf -o pipefail",
        "export PATH",
        "p=$PWD",
        """base64 -i %s | tr -d '\n' > %s""" % (src.path, output.path),
    ])
    ctx.action(
        inputs = [src],
        outputs = [output],
        command = cmd,
    )
    return struct(
        files = depset([output]),
    )

base_64 = rule(
    implementation = _base_64_impl,
    attrs = {
        "src": attr.label(allow_single_file = True),
        "dest": attr.output(),
    },
)
"""Return a file containing the base64 content of an input file

Args:
  src: The file to take the base64 of
  dest: The file that will contain the base64 of the src file
"""

def _get_class_list_impl(ctx):
    deps = ctx.files.deps
    dest = ctx.outputs.dest
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
    ])
    for file in ctx.files.deps:
        cmd += """ \\\n  && (jar tf $p/%s | grep '\.class$' | sed 's:\\/:.:g' | sed 's:\.class$::') >> %s""" % (file.path, dest.path)
    ctx.action(
        inputs = deps,
        outputs = [dest],
        command = cmd,
    )
    return struct(
        files = depset([dest]),
    )

get_class_list = rule(
    implementation = _get_class_list_impl,
    attrs = {
        "deps": attr.label_list(allow_files = [".srcjar", ".jar"]),
        "dest": attr.output(),
    },
)
"""Create a file listing all the classes in the provided jars

Args:
  srcs: The jars to list the classes of
  dest: The file to put the list in
"""

def _repack_archive(unpack, pack, dir, in_path, out_path):
    """Repackage an archive

    Args:
      unpack: The command to unpack the original archive
      pack: The command to pack the new archive
      dir: An optional dir to move the content into within the tarball
      in_path: The path to the original archive
      out_path: The path to the new archive
    """
    act_dir = "test" if not dir else "test/%s" % dir
    return " \\\n  && " + " \\\n  && ".join([
        "mkdir -p %s" % act_dir,
        "(cd %s && %s $p/%s)" % (act_dir, unpack, in_path),
        "(cd test && %s $p/%s .)" % (pack, out_path),
        "rm -rf test",
    ])

def _to_tar_impl(ctx):
    srcs = ctx.files.srcs
    ext = ctx.attr.extension
    dir = ctx.attr.dir
    tar = "tar cf"
    if is_tgz(ext):
        tar = "tar czf"
    if is_tbz(ext):
        tar = "tar cjf"
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
    ])
    outs = []
    for file in srcs:
        if is_jar(file.path):
            out = ctx.new_file(file.basename[:4] + ext)
            outs.append(out)
            cmd += _repack_archive("jar xf", tar, dir, file.path, out.path)
        if is_srcjar(file.path):
            out = ctx.new_file(file.basename[:7] + ext)
            outs.append(out)
            cmd += _repack_archive("jar xf", tar, dir, file.path, out.path)
        if is_zip(file.path):
            out = ctx.new_file(file.basename[:4] + ext)
            outs.append(out)
            cmd += _repack_archive("unzip", tar, dir, file.path, out.path)
        if is_tar(file.path):
            out = ctx.new_file(file.basename[:4] + ext)
            outs.append(out)
            cmd += _repack_archive("tar xf", tar, dir, file.path, out.path)
        if is_tgz(file.path):
            n = 4 if file.path.endswith(".tgz") else 7
            out = ctx.new_file(file.basename[:n] + ext)
            outs.append(out)
            cmd += _repack_archive("tar zxf", tar, dir, file.path, out.path)
        if is_tbz(file.path):
            n = 7 if file.path.endswith(".tar.bz2") else 9
            out = ctx.new_file(file.basename[:n] + ext)
            outs.append(out)
            cmd += _repack_archive("tar jxf", tar, dir, file.path, out.path)
    ctx.action(
        inputs = srcs,
        outputs = outs,
        command = cmd,
    )
    return struct(
        files = depset(outs),
    )

to_tar = rule(
    implementation = _to_tar_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".zip",
            ".jar",
            ".srcjar",
            ".tar",
            ".tgz",
            ".tar.gz",
            ".tar.bz2",
            ".tar.bzip2",
        ]),
        "dir": attr.string(),
        "extension": attr.string(mandatory = False, default = ".tar"),
    },
)
"""Return a file containing a list of all the classes inside the provided jars

Args:
  srcs: The files to be converted to tarballs
  dir: An optional dir to move the content into within the tarball
  extension: The output extension of the tarballs. It must start with a dot. Defaults to '.tar'
"""
