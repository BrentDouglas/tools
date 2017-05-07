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
load("//tools:ui.bzl", "extract_module", "extract_all_modules")


def _rollup_library_impl(ctx):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    cfg = ctx.file.cfg
    deps = ctx.files.deps
    rollup = ctx.file._rollup
    dest = ctx.outputs.dest

    srcs = []
    for dep in ctx.attr.srcs:
        if hasattr(dep, "js"):
            srcs.extend(dep.js.to_list())
        else:
            srcs.extend(dep.files.to_list())

    node = ["%s node_modules/rollup/bin/rollup" % ctx.file._node.path]
    node.append("--silent")
    node.extend(["--%s" % x for x in opts])
    node.extend(["--%s %s" % (k, sopts[k]) for k in sopts])
    node.extend(["-i %s" % src.path for src in srcs])
    node.append("-o %s" % dest.path)

    inputs = [ctx.file._node, rollup]
    if cfg:
        inputs.append(cfg)
        node.append("--config %s" % cfg.path)

    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
            extract_module(rollup.path),
        ] + extract_all_modules(ctx, ctx.attr.deps) +
        ["mkdir -p %s && cp %s %s" % (strip_base(file.dirname, base, gen_base), file.path, strip_base(file.path, base, gen_base)) for file in srcs] +
        ["export NODE_PATH=$p/node_modules"] +
        [" \\\n    ".join(node)],
    )
    ctx.actions.run_shell(
        inputs = inputs + srcs + deps,
        outputs = [dest],
        command = cmd,
    )
    return struct(files = depset([dest]))

rollup_library = rule(
    implementation = _rollup_library_impl,
    attrs = {
        "srcs": attr.label_list(),
        "cfg": attr.label(allow_single_file = True),
        "deps": attr.label_list(),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_rollup": attr.label(
            default = Label("@rollup//pkg"),
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
Compile JS using Rollup
"""