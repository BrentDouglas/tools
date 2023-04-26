load("//tools/java:java_test_suite.bzl", "java_test_suite")
load("//tools/java:java_package.bzl", "java_package")

def benchmark_binary_suite(
        name,
        **kwargs):
    """
    Generate binary rules for each benchmark individually.

    Args:
      name: The name of the test suite
      kargs: Other args for the java binaries run. See https://docs.bazel.build/versions/master/be/java.html#java_binary
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
    for src in srcs:
        clazz = src[src.rfind("/") + 1:-5]
        native.java_binary(
            name = clazz,
            main_class = src[src.rfind("java") + 1:-5].replace("/", "."),
            srcs = [src],
            deps = deps,
            **kwargs
        )
