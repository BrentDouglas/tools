load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def java_repositories(
        rules_jvm_external_version = "4.2",
        rules_jvm_external_sha256 = "cd1a77b7b02e8e008439ca76fd34f5b07aecb8c752961f9640dea15e9e5ba1ca"):
    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-%s" % rules_jvm_external_version,
        sha256 = rules_jvm_external_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % rules_jvm_external_version,
            "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % rules_jvm_external_version,
        ],
    )
