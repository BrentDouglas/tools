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

def _stylus_library_impl(ctx):
    base = ctx.bin_dir.path
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    dest = ctx.outputs.dest
    srcs = ctx.files.srcs
    deps = ctx.files.deps

    stylus = " ".join(
        ["%s node_modules/stylus/bin/stylus" % ctx.file._node.path] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        ["--import %s" % f.path for f in srcs] +
        ["> %s" % (dest.path)],
    )

    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
            extract_module(ctx.file._stylus.path),
        ] + [extract_module(dep.path) if not dep.path.startswith(base) else extract_module(dep.path[len(base) + 1:]) for dep in ctx.files.deps] +
        [
            "export NODE_PATH=$p/node_modules",
            stylus,
        ],
    )
    outs = [dest]
    cmd_file = ctx.new_file(ctx.label.name + "-stylus-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
    )
    outs = [dest]
    ctx.actions.run_shell(
        inputs = [ctx.file._node, ctx.file._stylus, cmd_file] + srcs + deps,
        outputs = outs,
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outs))

stylus_library = rule(
    implementation = _stylus_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".styl",
            ".css",
        ]),
        "deps": attr.label_list(allow_files = [
            ".tgz",
            ".srcjar",
            ".jar",
        ]),
        "dest": attr.output(),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_stylus": attr.label(
            default = Label("@stylus//pkg"),
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
