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

def _csso_library_impl(ctx):
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    srcs = ctx.files.srcs
    compressor = ctx.file._compressor
    dest = ctx.outputs.dest

    compress = " ".join(
        ["%s node_modules/csso-cli/bin/csso" % ctx.file._node.path] +
        ["-i %s" % x.path for x in srcs] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        ["-o %s" % dest.path],
    )

    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        extract_module(compressor.path),
        compress,
    ])
    outs = [dest]
    cmd_file = ctx.new_file(ctx.label.name + "-csso-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
    )
    ctx.actions.run_shell(
        inputs = [ctx.file._node, cmd_file, compressor] + srcs,
        outputs = outs,
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outs))

csso_library = rule(
    implementation = _csso_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".css",
        ]),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "dest": attr.output(),
        "_compressor": attr.label(
            default = Label("@csso-cli//pkg"),
            allow_single_file = True,
        ),
        "_node": attr.label(
            default = Label("@nodejs//:node"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
    },
)
"""Compress CSS files

Args:
  srcs: The css files to compress
  opts: Options to be passed on the command line that have no
    argument
  string_opts: Options to be passed on the command line that have an
    argument
  dest: The name of the compressed css file
"""
