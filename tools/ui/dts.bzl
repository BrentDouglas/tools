load(
    "//tools:util.bzl",
    "extract_file",
    "filter_filetypes",
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

def _process_file(file, base):
    """
    Helper for _dts_compile_impl
    """
    dir = strip_base(file.dirname, base)
    out = strip_base(file.path, base)
    return "mkdir -p $p/%s && ([ -e $p/%s ] || cp %s $p/%s)" % (dir, out, file.path, out)

def _type_definition_library_impl(ctx):
    base = ctx.bin_dir.path
    pkg = ctx.label.package
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    base_dir = base + "/" + pkg
    entry = '"' + '" "'.join([strip_base(file.path, base_dir) for file in filter_filetypes(dts_filetype, ctx.files.entry)]) + '"'
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    dts_bundle = ctx.file._dts_bundle
    dest = ctx.outputs.dest

    node = " ".join(
        ["%s node_modules/dts-bundle/lib/dts-bundle.js" % ctx.file._node.path] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        ["--baseDir ."] +
        ["--out %s" % dest.path] +
        ["--name %s" % ctx.attr.package_name if ctx.attr.package_name else ctx.label.name] +
        ["--main %s" % entry],
    )
    awk = """ awk '{ printf "\\42%s\\42,\\n        ", $1 }' """
    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
            extract_module(dts_bundle.path),
        ] + extract_all_modules(ctx, ctx.attr.deps) +
        [extract_file(file.path) for file in filter_filetypes(jar_filetype, srcs)] +
        ["export NODE_PATH=$p/node_modules"] +
        [_process_file(file, base_dir) for file in filter_filetypes(dts_filetype, srcs)] +
        [node],
    )
    cmd_file = ctx.new_file(ctx.label.name + "-dts-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
    )
    outs = [dest]
    ctx.actions.run_shell(
        inputs = [ctx.file._node, dts_bundle, cmd_file] + srcs + deps,
        outputs = outs,
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outs))

type_definition_library = rule(
    implementation = _type_definition_library_impl,
    attrs = {
        "package_name": attr.string(),
        "entry": attr.label_list(),
        "srcs": attr.label_list(),
        "deps": attr.label_list(),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_dts_bundle": attr.label(
            default = Label("@dts-bundle//pkg"),
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
"""Compile .d.ts files using dts-bundle
"""
