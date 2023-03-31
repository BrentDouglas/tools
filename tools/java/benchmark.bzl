load("//tools/java:java_test_suite.bzl", "java_test_suite")
load("//tools/java:java_package.bzl", "java_package")

def benchmark_library(
        name,
        **kwargs):
    """
    Generate test rules for each test individually.

    Args:
      name: The name of the test suite
      kargs: Other args for the test run. See https://docs.bazel.build/versions/master/be/java.html#java_test
    """
    deps = kwargs.pop("deps", [])
    jvm_args = kwargs.pop("jvm_args", []) + [""]
    srcs = kwargs.pop("srcs", [])
    if not srcs:
        srcs = native.glob(["*.java"])
    java_package(
        name = name,
        srcs = srcs,
        deps = deps,
    )
    test_names = []
    for src in srcs:
        clazz = src[src.rfind("/") + 1:-5]
        test_names.append(clazz)
        native.java_test(
            name = clazz,
            srcs = [src],
            deps = deps,
            **kwargs
        )
    native.test_suite(
        name = name + "-suite",
        tests = test_names,
    )

#def _benchmark_library_impl(ctx):
#    name = ctx.label.name
#    _profiler = ctx.files._profiler
#    command="""
#        set -euo pipefail;
#        mkdir -p {target} \
#            && xjc -d {target} -p {package} \
#            && jar cf {jar_name} -C {target} .
#    """.format(
#        jar_name=ctx.outputs.jar.path,
#        package=ctx.attr.package,
#        target=name,
#    )
#    outs = [ctx.outputs.jar]
#    ctx.actions.run_shell(
#        inputs=_profiler,
#        outputs=outs,
#        arguments=[],
#        command=command
#    )
#    return struct(files = depset(outs))
#
#benchmark_library = rule(
#    implementation = _benchmark_library_impl,
#    output_to_genfiles = True,
#    attrs = {
#        "_profiler": attr.label_list(default = [
#            Label("@async_profiler//:files"),
#        ]),
##        "schema": attr.label(allow_single_file=True),
#        "package": attr.string(),
#    },
#    outputs = {
#        "jar": "%{name}.srcjar"
#    },
#)
#"""Generate code from an xsd using java's xjc tool.
#
#Args:
#  schema: The xsd schema to build the java files from.
#  package: The package the output java files should be in.
#"""
