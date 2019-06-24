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

def _webfont_library_impl(ctx):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    outs = [ctx.actions.declare_file(x) for x in ctx.attr.outs]
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    template = ctx.file.template
    formats = ctx.attr.formats

    node = " \\\n    ".join(
        ["%s node_modules/webfont/dist/cli.js" % ctx.file._node.path] +
        [f.path for f in srcs] +
        ["--dest %s" % outs[0].dirname] +
        ["--template %s" % template.path] +
        ["--formats [%s]" % ",".join(["%s" % k for k in formats])] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts],
    )

    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
            extract_module(ctx.file._webfont.path),
        ] + [extract_module(dep.short_path) for dep in ctx.files.deps] +
        [
            "export NODE_PATH=$p/node_modules",
            node,
        ],
    )
    cmd_file = ctx.actions.declare_file(ctx.label.name + "-webfont-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
    )
    ctx.actions.run_shell(
        inputs = [ctx.file._webfont, template, cmd_file] + srcs + deps,
        outputs = outs,
        tools = [ctx.file._node],
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outs))

webfont_library = rule(
    implementation = _webfont_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".svg",
        ]),
        "deps": attr.label_list(allow_files = [
            ".tgz",
            ".srcjar",
            ".jar",
        ]),
        "formats": attr.string_list(),
        "template": attr.label(allow_single_file = True),
        "outs": attr.string_list(),
        "opts": attr.string_dict(),
        "string_opts": attr.string_dict(),
        "_webfont": attr.label(
            default = Label("@webfont//pkg"),
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
