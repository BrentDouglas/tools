load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def java_repositories(
        rules_jvm_external_version = "5.1",
        rules_jvm_external_sha256 = "8c3b207722e5f97f1c83311582a6c11df99226e65e2471086e296561e57cc954"):
    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-%s" % rules_jvm_external_version,
        sha256 = rules_jvm_external_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_jvm_external/releases/download/%s/rules_jvm_external-%s.tar.gz" % (rules_jvm_external_version, rules_jvm_external_version),
            "https://github.com/bazelbuild/rules_jvm_external/releases/download/%s/rules_jvm_external-%s.tar.gz" % (rules_jvm_external_version, rules_jvm_external_version),
        ],
    )
