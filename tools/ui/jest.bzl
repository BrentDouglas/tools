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

def _jest_test_impl(ctx):
    """
    Create a test using ava.
    """
    run = " ".join(
        ["%s node_modules/jest/bin/jest \\\n    " % ctx.file._node.path],
    ) + " \\\n    ".join([strip_base(x.path) for x in ctx.files.srcs])
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        extract_module(ctx.file._jest.path),
    ] + extract_all_modules(ctx, ctx.attr.deps) + [
        "OUT_DIR=$(mktemp -d -t tmp.XXXXXXXXX)",
        "trap cleanup EXIT",
        "export NODE_PATH=$p/node_modules",
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
    files = [ctx.file._node, ctx.file._jest, ctx.outputs.executable] + ctx.files.srcs + ctx.files.deps
    runfiles = ctx.runfiles(
        files = files,
        collect_data = True,
    )
    return struct(
        files = depset(files),
        runfiles = runfiles,
    )

jest_test = rule(
    implementation = _jest_test_impl,
    test = True,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".js",
        ]),
        "deps": attr.label_list(),
        "_jest": attr.label(
            default = Label("@jest//pkg"),
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
