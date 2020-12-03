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

def _html_compressor_library_impl(ctx):
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    compressor = ctx.file._compressor
    output = ctx.outputs.dest

    jar = " ".join(
        ["java -jar $p/jars/%s" % compressor.basename] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        ["--output %s" % output.path] +
        [" ".join([x.path for x in srcs])],
    )

    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        "mkdir $p/jars",
        "cp %s $p/jars/%s" % (compressor.path, compressor.basename),
    ] + ["cp %s $p/jars/%s" % (x.path, x.basename) for x in deps] + [
        jar,
    ])
    ctx.actions.run_shell(
        inputs = [compressor] + srcs + deps,
        outputs = [output],
        command = cmd,
    )
    return struct(
        files = depset([output]),
    )

html_compressor_library = rule(
    implementation = _html_compressor_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".html",
        ]),
        "deps": attr.label_list(),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_compressor": attr.label(
            default = Label("@build_m2//:com_googlecode_htmlcompressor_htmlcompressor"),
            allow_single_file = True,
        ),
        "dest": attr.output(),
    },
)
"""
Compress HTML files using googles HTML Compressor
"""

def _html_minifier_library_impl(ctx):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    deps = ctx.files.deps
    html_minifier = ctx.file._html_minifier
    dest = ctx.outputs.dest

    srcs = []
    for dep in ctx.attr.srcs:
        if hasattr(dep, "js"):
            srcs.extend(dep.js.to_list())
        else:
            srcs.extend(dep.files.to_list())

    node = ["%s node_modules/html-minifier/cli.js" % ctx.file._node.path]
    node.extend(["--%s" % x for x in opts])
    node.extend(["--%s %s" % (k, sopts[k]) for k in sopts])
    node.append("-o %s" % dest.path)
    node.extend([src.path for src in srcs])

    inputs = [html_minifier]

    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
            extract_module(html_minifier.path),
        ] + extract_all_modules(ctx, ctx.attr.deps) +
        ["mkdir -p %s && cp %s %s" % (strip_base(file.dirname, base, gen_base), file.path, strip_base(file.path, base, gen_base)) for file in srcs] +
        ["export NODE_PATH=$p/node_modules"] +
        [" \\\n    ".join(node)],
    )
    ctx.actions.run_shell(
        inputs = inputs + srcs + deps,
        outputs = [dest],
        tools = [ctx.file._node],
        command = cmd,
    )
    return struct(files = depset([dest]))

html_minifier_library = rule(
    implementation = _html_minifier_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".html",
        ]),
        "deps": attr.label_list(),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_html_minifier": attr.label(
            default = Label("@html-minifier//pkg"),
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
"""
Compress HTML using html-minifier
"""
