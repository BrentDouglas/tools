load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def java_repositories(
        rules_jvm_external_version = "3.3",
        rules_jvm_external_sha256 = "d85951a92c0908c80bd8551002d66cb23c3434409c814179c0ff026b53544dab"):
    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-%s" % rules_jvm_external_version,
        sha256 = rules_jvm_external_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % rules_jvm_external_version,
            "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % rules_jvm_external_version,
        ],
    )
