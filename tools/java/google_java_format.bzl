def _google_java_format_test_impl(ctx):
    name = ctx.label.name
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    formatter = ctx.file._formatter
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts

    cmds = ["export RETVAL=0"]
    for src in srcs:
        cmd = " \\\n  ".join(
            ["java -jar %s" % formatter.path] +
            ["--set-exit-if-changed"] +
            ["--%s" % x for x in opts] +
            ["--%s %s" % (k, sopts[k]) for k in sopts] +
            [src.path] +
            [" > %s.formatted" % src.path] +
            ["|| { export RETVAL=1; find . ; echo '%s'; diff %s %s.formatted; }" % (src.path, src.path, src.path)],
        )
        cmds.append(cmd)
    cmds.append("exit ${RETVAL}")

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = " \\\n ; ".join(cmds),
        is_executable = True,
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
        "_formatter": attr.label(allow_single_file = True, default = Label("@google_java_format//jar")),
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
