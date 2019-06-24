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

def _uglify_library_impl(ctx):
    base = ctx.bin_dir.path
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    dest = ctx.outputs.dest
    source_map = ctx.outputs.source_map
    inline_map = ctx.attr.inline_map
    outs = [dest] + ([source_map] if source_map and not inline_map else [])
    srcs = ctx.files.srcs
    sources = "url=inline" if inline_map else "url='%s',filename='%s'" % (source_map.basename, source_map.basename) if source_map else ""
    uglify = " ".join(
        ["%s node_modules/uglify-js/bin/uglifyjs" % ctx.file._node.path] +
        [" ".join([x.path for x in srcs])] +
        (["--source-map content=inline,includeSources,%s" % sources] if source_map or inline_map else []) +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        ["--output %s" % dest.path],
    )
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        extract_module(ctx.file._uglify.path),
        "export NODE_PATH=$p/node_modules",
        uglify,
    ])
    cmd_file = ctx.actions.declare_file(ctx.label.name + "-uglify-library-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
    )
    ctx.actions.run_shell(
        inputs = [cmd_file, ctx.file._uglify] + ctx.files.srcs,
        outputs = outs,
        tools = [ctx.file._node],
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outs))

uglify_library = rule(
    implementation = _uglify_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".js",
        ]),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "source_map": attr.output(),
        "inline_map": attr.bool(default = False),
        "dest": attr.output(),
        "_uglify": attr.label(
            default = Label("@uglify-js//pkg"),
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
"""Minify javascript files using UglifyJs

Args:
  srcs: The js files to compress
  deps: NPM modules that are needed to run uglify
  source_map: The name of an optional output source map file. Not
    required if source maps are inlined.
  inline_map: When set to true the output source maps will be
    appended to the javscript file.
  dest: The name of the compressed js file
  opts: Options to be passed on the command line that have no
    argument
  string_opts: Options to be passed on the command line that have an
    argument
"""
