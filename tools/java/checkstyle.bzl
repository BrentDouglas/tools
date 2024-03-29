load("//tools:util.bzl", "strip_base")

def _checkstyle_test_impl(ctx):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    name = ctx.label.name
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    config = ctx.file.config
    properties = ctx.file.properties
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts

    classpath = ""
    add = False
    for file in ctx.files._classpath:
        if add:
            classpath += ":"
        add = True
        classpath += strip_base(file.path, base, gen_base)
    for file in ctx.files.deps:
        classpath += ":" + file.path

    args = ""
    inputs = []
    if config:
        args += " -c %s" % config.path
        inputs.append(config)
    if properties:
        args += " -p %s" % properties.path
        inputs.append(properties)

    cmd = " ".join(
        ["java -cp %s com.puppycrawl.tools.checkstyle.Main" % classpath] +
        [args] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        [x.path for x in srcs],
    )

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = cmd,
        is_executable = True,
    )
    files = [ctx.outputs.executable] + ctx.files.data + srcs + deps + ctx.files._classpath + inputs
    runfiles = ctx.runfiles(
        files = files,
        collect_data = True,
    )
    return struct(
        files = depset(files),
        runfiles = runfiles,
    )

checkstyle_test = rule(
    implementation = _checkstyle_test_impl,
    test = True,
    attrs = {
        "_classpath": attr.label_list(default = [
            Label("@checkstyle_m2//:com_puppycrawl_tools_checkstyle"),
            Label("@checkstyle_m2//:commons_beanutils_commons_beanutils"),
            Label("@checkstyle_m2//:commons_cli_commons_cli"),
            Label("@checkstyle_m2//:commons_collections_commons_collections"),
            Label("@checkstyle_m2//:org_slf4j_slf4j_api"),
            Label("@checkstyle_m2//:org_slf4j_jcl_over_slf4j"),
            Label("@checkstyle_m2//:antlr_antlr"),
            Label("@checkstyle_m2//:org_antlr_antlr4_runtime"),
            Label("@checkstyle_m2//:com_google_guava_guava"),
        ]),
        "config": attr.label(allow_single_file = True),
        "data": attr.label_list(allow_files = True),
        "properties": attr.label(allow_single_file = True),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
    },
)
"""Run checkstyle

Args:
  config: A checkstyle configuration file
  properties: A properties file to be used
  opts: Options to be passed on the command line that have no
    argument
  string_opts: Options to be passed on the command line that have an
    argument
  srcs: The files to check
"""
