load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def go_repositories(
        io_bazel_rules_go_version = "v0.39.0",
        io_bazel_rules_go_sha256 = "6b65cb7917b4d1709f9410ffe00ecf3e160edf674b78c54a894471320862184f",
        bazel_gazelle_version = "v0.30.0",
        bazel_gazelle_sha256 = "727f3e4edd96ea20c29e8c2ca9e8d2af724d8c7778e7923a854b2c80952bc405"):
    http_archive(
        name = "io_bazel_rules_go",
        sha256 = io_bazel_rules_go_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/%s/rules_go-%s.zip" % (io_bazel_rules_go_version, io_bazel_rules_go_version),
            "https://github.com/bazelbuild/rules_go/releases/download/%s/rules_go-%s.zip" % (io_bazel_rules_go_version, io_bazel_rules_go_version),
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
