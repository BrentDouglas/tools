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

def _webpack_compile_impl(ctx):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    entry = ctx.attr.entry
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    webpack = ctx.file._webpack
    source_map_loader = ctx.file._source_map_loader
    dest = ctx.outputs.dest

    config_content = """
    module.exports = {
      module: {
        rules: [
          {
            test: /\.js$/,
            use: ["source-map-loader"],
            enforce: "pre"
          }
        ]
      }
    };
    """

    node = " ".join(
        ["%s node_modules/webpack/bin/webpack" % ctx.file._node.path] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts],
    )

    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
            extract_module(webpack.path),
            extract_module(source_map_loader.path),
        ] + extract_all_modules(ctx, ctx.attr.deps) +
        [extract_file(file.path) for file in jar_filetype.filter(srcs)] +
        ["mkdir -p %s && cp %s %s" % (strip_base(file.dirname, base, gen_base), file.path, strip_base(file.path, base, gen_base)) for file in srcs] +
        ["export NODE_PATH=$p/node_modules"] +
        ["echo '%s' > webpack.config.js" % (config_content)] +
        ["%s --devtool inline-source-map %s %s" % (node, entry, dest.path)],
    )
    ctx.actions.run_shell(
        inputs = [ctx.file._node, webpack, source_map_loader] + srcs + deps,
        outputs = [dest],
        command = cmd,
    )
    return struct(files = depset([dest]))

webpack_compile = rule(
    implementation = _webpack_compile_impl,
    attrs = {
        "entry": attr.string(),
        "srcs": attr.label_list(),
        "deps": attr.label_list(),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_webpack": attr.label(
            default = Label("@webpack//pkg"),
            allow_single_file = True,
        ),
        "_source_map_loader": attr.label(
            default = Label("@source-map-loader//pkg"),
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
Compile JS using Webpack
"""
