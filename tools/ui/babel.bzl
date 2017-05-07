load(
    "//tools:util.bzl",
    "extract_file",
    "get_debug_commands",
    "get_path",
    "get_path_of",
    "get_post_debug_commands",
    "is_any_jar",
    "is_archive",
    "is_tar",
    "is_tgz",
    "join_dict",
    "join_list",
    "list_file",
    "strip_base",
)
load("//tools:ui.bzl", "extract_all_modules", "extract_module")

def _babel_library_impl(ctx):
    base = ctx.bin_dir.path
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    opts = ctx.attr.opts
    dest = ctx.outputs.dest
    sopts = ctx.attr.string_opts

    node = " ".join(
        ["%s node_modules/babel-cli/bin/babel.js" % ctx.file._node.path] +
        [x.path for x in srcs] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        ["> %s" % (dest.path)],
    )
    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
            extract_module(ctx.file._babel.path),
        ] +
        [extract_module(dep.path) if not dep.path.startswith(base) else extract_module(dep.path[len(base) + 1:]) for dep in ctx.files.deps] +
        ["export NODE_PATH=$p/node_modules"] +
        [node],
    )

    outputs = [dest]
    cmd_file = ctx.new_file(ctx.label.name + "babel-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
        executable = True,
    )
    ctx.actions.run_shell(
        inputs = [ctx.file._node, cmd_file] + srcs + deps + [ctx.file._babel],
        outputs = outputs,
        executable = cmd_file,
    )
    return struct(
        files = depset(outputs),
    )

babel_library = rule(
    implementation = _babel_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".js",
            ".srcjar",
            ".jar",
        ]),
        "deps": attr.label_list(allow_files = [
            ".tgz",
            ".srcjar",
            ".jar",
        ]),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_babel": attr.label(
            default = Label("@babel-cli//pkg"),
            allow_single_file = True,
        ),
        "_node": attr.label(
            default = Label("@nodejs//:node"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
        "dest": attr.output(),
    },
)
"""Convert files using babel.

Args:
  srcs: The javascript source files to convert. They may either be regular
    files or wrapped in a jar/srcjar container.
  deps: NPM dependencies (e.g. @types/lodash)
  opts: Boolean options for tcs. They end up in the form
    "option": true. The values must be the strings "true" or
    "false" as they end up as json boolean primitives.
  string_opts: String options with an argument to pass to tcs. They in
    up in the form "option": "value". The values may be any string.
  dest: The output file
"""
