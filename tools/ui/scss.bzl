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
load("//tools/ui:concat.bzl", "concat")

def _scss_library_impl(ctx):
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    entry = ctx.files.entry
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    scss = ctx.file._scss
    output = ctx.outputs.css

    node = " ".join(
        ["%s node_modules/node-sass/bin/node-sass" % ctx.file._node.path] +
        ["--include-path node_modules"] +
        ["--include-path ./%s" % ctx.label.package] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts],
    )

    files = [(x, ctx.new_file(x.basename[:-5] + ".css")) for x in entry]

    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        extract_module(scss.path),
    ] + extract_all_modules(ctx, ctx.attr.deps) + [
        "export NODE_PATH=$p/node_modules",
    ] + [
        "cat %s | %s > %s" % (x[0].path, node, x[1].path)
        for x in files
    ])
    tmp_files = [x[1] for x in files]
    ctx.actions.run_shell(
        inputs = [ctx.file._node, scss] + entry + srcs + deps,
        outputs = tmp_files,
        command = cmd,
    )
    return concat(
        ctx,
        False,
        True,
        True,
        ["../"],
        tmp_files,
        output,
        ctx.file._concat,
        ctx.file._sourcemaps,
    )

scss_library = rule(
    implementation = _scss_library_impl,
    attrs = {
        "entry": attr.label_list(allow_files = [
            ".scss",
        ]),
        "srcs": attr.label_list(allow_files = [
            ".scss",
        ]),
        "deps": attr.label_list(),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_scss": attr.label(
            default = Label("@node-sass//pkg"),
            allow_single_file = True,
        ),
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
    },
    outputs = {
        "css": "%{name}.css",
    },
)
"""Compile SCSS to CSS

Args:
  entry: The files from which scss should start resolving things
  srcs: The scss src files
  deps: NPM modules that are needed to run the linter
  opts: Options to be passed on the command line that have no
    argument
  string_opts: Options to be passed on the command line that have an
    argument
"""
