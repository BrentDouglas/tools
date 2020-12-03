load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def stardoc_repositories(
        bazel_skylib_version = "1.0.3",
        bazel_skylib_sha256 = "7ac0fa88c0c4ad6f5b9ffb5e09ef81e235492c873659e6bb99efb89d11246bcb",
        io_bazel_stardoc_version = "0.4.0",
        io_bazel_stardoc_sha256 = "6d07d18c15abb0f6d393adbd6075cd661a2219faab56a9517741f0fc755f6f3c"):
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
            "https://github.com/bazelbuild/stardoc/archive/%s.tar.gz" % io_bazel_stardoc_version
        ],
    )
