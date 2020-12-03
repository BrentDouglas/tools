load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def go_repositories(
        io_bazel_rules_go_version = "0.18.6",
        io_bazel_rules_go_sha256 = "f04d2373bcaf8aa09bccb08a98a57e721306c8f6043a2a0ee610fd6853dcde3d",
        bazel_gazelle_version = "0.17.0",
        bazel_gazelle_sha256 = "3c681998538231a2d24d0c07ed5a7658cb72bfb5fd4bf9911157c0e9ac6a2687"):
    http_archive(
        name = "io_bazel_rules_go",
        sha256 = io_bazel_rules_go_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/%s/rules_go-%s.tar.gz" % (io_bazel_rules_go_version, io_bazel_rules_go_version),
            "https://github.com/bazelbuild/rules_go/releases/download/%s/rules_go-%s.tar.gz" % (io_bazel_rules_go_version, io_bazel_rules_go_version),
        ],
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = bazel_gazelle_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/%s/bazel-gazelle-%s.tar.gz" % (bazel_gazelle_version, bazel_gazelle_version),
            "https://github.com/bazelbuild/bazel-gazelle/releases/download/%s/bazel-gazelle-%s.tar.gz" % (bazel_gazelle_version, bazel_gazelle_version),
        ],
    )
