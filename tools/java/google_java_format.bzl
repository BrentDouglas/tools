def _google_java_format_test_impl(ctx):
    name = ctx.label.name
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    formatter = ctx.file._formatter
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts

    cmd = " \\\n  ".join(
        ["java -jar %s" % formatter.path] +
        ["--set-exit-if-changed --dry-run"] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        [x.path for x in srcs],
    )

    ctx.file_action(
        output = ctx.outputs.executable,
        content = cmd,
        executable = True,
    )
    files = [ctx.outputs.executable, formatter] + srcs + deps
    runfiles = ctx.runfiles(
        files = files,
        collect_data = True,
    )
    return struct(
        files = depset(files),
        runfiles = runfiles,
    )

google_java_format_test = rule(
    implementation = _google_java_format_test_impl,
    test = True,
    attrs = {
        "_formatter": attr.label(allow_single_file=True, default = Label("@google_java_format//jar")),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
    },
)
"""Run google-java-format

Args:
  opts: Options to be passed on the command line that have no
    argument
  string_opts: Options to be passed on the command line that have an
    argument
  srcs: The files to check
"""
