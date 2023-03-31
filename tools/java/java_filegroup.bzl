load("@io_machinecode_tools//tools/java:checkstyle.bzl", "checkstyle_test")
load("@io_machinecode_tools//tools/java:google_java_format.bzl", "google_java_format_test")

def java_filegroup(
        name,
        srcs,
        config = "@io_machinecode_tools//tools/checkstyle:config",
        header = "@io_machinecode_tools//tools/checkstyle:header"):
    if not srcs:
        srcs = native.glob(["*.java"])
    native.filegroup(
        name = name,
        srcs = srcs,
    )

    checkstyle_test(
        name = "check",
        srcs = [
            ":" + name,
        ],
        config = config,
        data = [
            header,
        ],
        tags = ["check"],
    )

    google_java_format_test(
        name = "format",
        srcs = [
            ":" + name,
        ],
        tags = ["check"],
    )
