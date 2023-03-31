load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def pkg_repositories(
        rules_pkg_version = "0.9.0",
        rules_pkg_sha256 = "335632735e625d408870ec3e361e192e99ef7462315caa887417f4d88c4c8fb8"):
    http_archive(
        name = "rules_pkg",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/%s/rules_pkg-%s.tar.gz" % (rules_pkg_version, rules_pkg_version),
            "https://github.com/bazelbuild/rules_pkg/releases/download/%s/rules_pkg-%s.tar.gz" % (rules_pkg_version, rules_pkg_version),
        ],
        sha256 = rules_pkg_sha256,
    )
