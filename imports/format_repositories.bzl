load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

def format_repositories(
        google_java_format_version = "1.7",
        google_java_format_sha256 = "0894ee02019ee8b4acd6df09fb50bac472e7199e1a5f041f8da58d08730694aa",
        com_github_bazelbuild_buildtools_version = "49a6c199e3fbf5d94534b2771868677d3f9c6de9",
        com_github_bazelbuild_buildtools_sha256 = "edf39af5fc257521e4af4c40829fffe8fba6d0ebff9f4dd69a6f8f1223ae047b",
        bazel_gazelle_version = "0.15.0",
        bazel_gazelle_sha256 = "6e875ab4b6bf64a38c352887760f21203ab054676d9c1b274963907e0768740d",
        io_bazel_rules_go_version = "0.16.3",
        io_bazel_rules_go_sha256 = "b7a62250a3a73277ade0ce306d22f122365b513f5402222403e507f2f997d421"):
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
