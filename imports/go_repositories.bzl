load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def go_repositories(
        io_bazel_rules_go_version = "0.18.3",
        io_bazel_rules_go_sha256 = "b7a62250a3a73277ade0ce306d22f122365b513f5402222403e507f2f997d499",
        bazel_gazelle_version = "0.17.0",
        bazel_gazelle_sha256 = "3c681998538231a2d24d0c07ed5a7658cb72bfb5fd4bf9911157c0e9ac6a2687"):
    http_archive(
        name = "io_bazel_rules_go",
        sha256 = io_bazel_rules_go_sha256,
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/%s/rules_go-%s.tar.gz" % (io_bazel_rules_go_version, io_bazel_rules_go_version)],
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = bazel_gazelle_sha256,
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/%s/bazel-gazelle-%s.tar.gz" % (bazel_gazelle_version, bazel_gazelle_version)],
    )