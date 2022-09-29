load("//tools/java:checkstyle.bzl", "checkstyle_test")
load("//tools/java:google_java_format.bzl", "google_java_format_test")

def java_package(
        name,
        **kwargs):
    srcs = kwargs.pop("srcs", [])
    if not srcs:
        srcs = native.glob(["*.java"])
    srcs_name = kwargs.pop("srcs_name", "srcs")
    native.filegroup(
        name = srcs_name,
        srcs = srcs,
    )

    native.java_library(
        name = name,
        srcs = [":%s" % srcs_name],
        **kwargs
    )

    checkstyle_test(
        name = "check",
        srcs = [":%s" % srcs_name],
        config = "//tools/checkstyle:config",
        data = [
            "//tools/checkstyle:header",
        ],
        tags = ["check"],
    )

    google_java_format_test(
        name = "format",
        srcs = [":%s" % srcs_name],
        tags = ["check"],
    )
