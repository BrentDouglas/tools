load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

def skydoc_repositories(
        bazel_skylib_version = "0.8.0",
        bazel_skylib_sha256 = "2ea8a5ed2b448baf4a6855d3ce049c4c452a6470b1efd1504fdb7c1c134d220a",
        io_bazel_skydoc_version = "0.3.0",
        io_bazel_skydoc_sha256 = "c2d66a0cc7e25d857e480409a8004fdf09072a1bd564d6824441ab2f96448eea"):
    http_archive(
        name = "bazel_skylib",
        sha256 = bazel_skylib_sha256,
        strip_prefix = "bazel-skylib-" + bazel_skylib_version,
        urls = ["https://github.com/bazelbuild/bazel-skylib/archive/%s.tar.gz" % bazel_skylib_version],
    )

    http_archive(
        name = "io_bazel_skydoc",
        sha256 = io_bazel_skydoc_sha256,
        strip_prefix = "skydoc-" + io_bazel_skydoc_version,
        urls = ["https://github.com/bazelbuild/skydoc/archive/%s.tar.gz" % io_bazel_skydoc_version],
    )
