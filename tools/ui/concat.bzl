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

def _concat_library_impl(ctx):
    return concat(
        ctx,
        ctx.attr.refs,
        ctx.attr.maps,
        ctx.attr.inline,
        ctx.attr.strip,
        ctx.files.srcs,
        ctx.outputs.dest,
        ctx.file._concat,
        ctx.file._sourcemaps,
    )

def concat(ctx, refs, maps, inline, strip, srcs, dest, concat, sourcemaps):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    run = " \\\n    ".join([
        "%s %s" % (ctx.file._node.path, concat.path),
        "-r %s" % ("true" if refs else "false"),
        "-m %s" % ("true" if maps else "false"),
        "-i %s" % ("true" if inline else "false"),
    ] + ["-s '%s'" % val for val in strip] + [
        "-d %s --" % dest.path,
    ]) + " \\\n    "
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        extract_module(sourcemaps.path),
        "export NODE_PATH=$p/node_modules",
        "(cp -r %s/* $p/ 2>/dev/null || true)" % base,
        "(cp -r %s/* $p/ 2>/dev/null || true)" % gen_base,
    ])
    add_files = False
    for file in srcs:
        if is_any_jar(file.path):
            add_files = True
            cmd += """ \\\n  && (jar xf $p/%s)""" % (file.path)
            cmd += """ \\\n  && (jar tf $p/%s | awk '{printf " """ % (file.path) + """%s\\n", $1}') >> classes.list"""
        else:
            run += " \\\n  %s" % strip_base(file.path, base, gen_base)
    if add_files:
        run += " \\\n  @classes.list"
    if inline:
        outs = [dest]
    else:
        outs = [dest, ctx.actions.declare_file(dest.basename + ".map")]

    cmd_file = ctx.actions.declare_file(ctx.label.name + "-concat-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd + " \\\n  && " + run,
    )
    ctx.actions.run_shell(
        inputs = [ctx.file._concat, ctx.file._sourcemaps, cmd_file] + srcs,
        outputs = outs,
        tools = [ctx.file._node],
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outs))

concat_library = rule(
    implementation = _concat_library_impl,
    attrs = {
        "_concat": attr.label(
            default = Label("//tools/ui:concat"),
            allow_single_file = True,
        ),
        "_sourcemaps": attr.label(
            default = Label("@source-map//pkg"),
            allow_single_file = True,
        ),
        "_node": attr.label(
            default = Label("@nodejs//:node"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
        "srcs": attr.label_list(allow_files = True),
        "dest": attr.output(mandatory = True),
        "strip": attr.string_list(default = ["../"]),
        "refs": attr.bool(default = False),
        "maps": attr.bool(default = True),
        "inline": attr.bool(default = True),
    },
)
"""Concat a list of files into one.

It can deal with raw input files and jar and srcjar containers of files.

Args:
  srcs: The files to concat together.
  dest: The output filename.
  refs: If true typescript files being concatted in an order resolved from their
    references annotations, their imports and their exports.
  maps: If true generate source maps of the input.
  inline: If true and maps is true then generate inline maps.
  strip: A list of prefixes to strip from output file names in the source maps.
    This can be used to change how the directory structure is displayed in devtools.
"""
