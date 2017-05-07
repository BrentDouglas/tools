load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

def format_repositories(
        google_java_format_version = "1.6",
        google_java_format_sha256 = "73faf7c9b95bffd72933fa24f23760a6b1d18499151cb39a81cda591ceb7a5f4",
        com_github_bazelbuild_buildtools_version = "49a6c199e3fbf5d94534b2771868677d3f9c6de9",
        com_github_bazelbuild_buildtools_sha256 = "edf39af5fc257521e4af4c40829fffe8fba6d0ebff9f4dd69a6f8f1223ae047b",
        io_bazel_rules_go_version = "0.16.2",
        io_bazel_rules_go_sha256 = "f87fa87475ea107b3c69196f39c82b7bbf58fe27c62a338684c20ca17d1d8613"):
    http_jar(
        name = "google_java_format",
        sha256 = google_java_format_sha256,
        url = " https://github.com/google/google-java-format/releases/download/google-java-format-%s/google-java-format-%s-all-deps.jar" % (google_java_format_version, google_java_format_version),
    )

    http_archive(
        name = "io_bazel_rules_go",
        sha256 = io_bazel_rules_go_sha256,
        url = "https://github.com/bazelbuild/rules_go/releases/download/%s/rules_go-%s.tar.gz" % (io_bazel_rules_go_version, io_bazel_rules_go_version),
    )

    http_archive(
        name = "com_github_bazelbuild_buildtools",
        url = "https://github.com/bazelbuild/buildtools/archive/%s.zip" % com_github_bazelbuild_buildtools_version,
        strip_prefix = "buildtools-%s" % com_github_bazelbuild_buildtools_version,
        sha256 = com_github_bazelbuild_buildtools_sha256,
    )
