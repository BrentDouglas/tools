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

def _jasmine_test_impl(ctx):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    inputs = [ctx.file._node, ctx.file._jasmine, ctx.outputs.executable]

    debug_cmds = []
    if ctx.attr.debug == "node":
        debug = " --inspect-brk"
    elif ctx.attr.debug == "jasmine":
        debug = " --inspect"
    elif ctx.attr.debug == "rule":
        debug = ""
        debug_cmds = get_debug_commands(ctx)
    else:
        debug = ""

    run = " ".join(
        ["%s %s node_modules/jasmine-node/bin/jasmine-node" % (ctx.file._node.path, debug)] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts],
    ) + " \\\n    "
    run += " \\\n    ".join([strip_base(x.path, base, gen_base) for x in ctx.files.srcs])

    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        extract_module(ctx.file._jasmine.path),
    ] + [extract_module(strip_base(dep.path, base, gen_base)) for dep in ctx.files.deps] + [
        "OUT_DIR=$(mktemp -d -t tmp.XXXXXXXXX)",
        "trap cleanup EXIT",
        "export NODE_PATH=$p/node_modules",
    ] + debug_cmds + [
        run + " | tee ${OUT_DIR}/log",
        "grep '0 failures' ${OUT_DIR}/log",
        "exit $?",
    ])
    content = "\n".join([
        "function cleanup() {",
        "  rm -rf ${OUT_DIR}",
        "}",
        cmd,
    ])
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = content,
        is_executable = True,
    )
    files = inputs + ctx.files.srcs + ctx.files.deps
    runfiles = ctx.runfiles(
        files = files,
        collect_data = True,
    )
    return struct(
        files = depset(files),
        runfiles = runfiles,
    )

jasmine_test = rule(
    implementation = _jasmine_test_impl,
    test = True,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".js",
        ]),
        "debug": attr.string(),
        "deps": attr.label_list(),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_jasmine": attr.label(
            default = Label("@jasmine-node//pkg"),
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
"""Create a test using jamine-node.

Args:
  srcs: The tests to run
  deps: NPM modules that are needed to run the tests
"""
