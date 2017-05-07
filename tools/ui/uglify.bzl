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
    map = ctx.outputs.map
    outs = [dest] + ([map] if map else [])
    srcs = ctx.files.srcs
    uglify = " ".join(
        ["%s node_modules/uglify-js/bin/uglifyjs" % ctx.file._node.path] +
        [" ".join([x.path for x in srcs])] +
        (["--source-map %s" % map.path] if map else []) +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        ["> %s" % dest.path],
    )
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        extract_module(ctx.file._uglify.path),
        #        ] + [extract_module(dep.path) if not dep.path.startswith(base) else extract_module(dep.path[len(base) + 1:]) for dep in ctx.files.deps] + [
        "export NODE_PATH=$p/node_modules",
        uglify,
    ])
    cmd_file = ctx.new_file(ctx.label.name + "-js-compress-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
    )
    ctx.actions.run_shell(
        inputs = [ctx.file._node, cmd_file, ctx.file._uglify] + ctx.files.srcs,
        outputs = outs,
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
        "map": attr.output(),
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
  map: The name of an optional output source map file. Not
    required if source maps are inlined.
  dest: The name of the compressed js file
  opts: Options to be passed on the command line that have no
    argument
  string_opts: Options to be passed on the command line that have an
    argument
"""
