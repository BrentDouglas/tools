load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def stardoc_repositories(
        bazel_skylib_version = "1.4.1",
        bazel_skylib_sha256 = "060426b186670beede4104095324a72bd7494d8b4e785bf0d84a612978285908",
        io_bazel_stardoc_version = "0.5.3",
        io_bazel_stardoc_sha256 = "fc95cd29422f1d67395352804d03252aa77714e88dcbefd4d3b070d70ed75de7"):
    http_archive(
        name = "bazel_skylib",
        sha256 = bazel_skylib_sha256,
        strip_prefix = "bazel-skylib-" + bazel_skylib_version,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/%s/bazel-skylib-%s.tar.gz" % (bazel_skylib_version, bazel_skylib_version),
            "https://github.com/bazelbuild/bazel-skylib/archive/%s.tar.gz" % bazel_skylib_version,
        ],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = io_bazel_stardoc_sha256,
        strip_prefix = "stardoc-" + io_bazel_stardoc_version,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/stardoc/releases/download/%s/stardoc-%s.tar.gz" % (io_bazel_stardoc_version, io_bazel_stardoc_version),
            "https://github.com/bazelbuild/stardoc/archive/%s.tar.gz" % io_bazel_stardoc_version,
        ],
    )
