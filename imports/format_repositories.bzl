load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

def format_repositories(
        google_java_format_version = "1.16.0",
        google_java_format_sha256 = "82819a2c5f7067712e0233661b864c1c034f6657d63b8e718b4a50e39ab028f6",
        com_github_bazelbuild_buildtools_version = "6.1.0",
        com_github_bazelbuild_buildtools_sha256 = "4e3e330089960e0962f908ba6feac0859faed070c5292e5cc207cfcc6a428fe5",
        com_google_protobuf_version = "3.13.0",
        com_google_protobuf_sha256 = "9b4ee22c250fe31b16f1a24d61467e40780a3fbb9b91c3b65be2a376ed913a1a"):
    http_jar(
        name = "google_java_format",
        sha256 = google_java_format_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/google/google-java-format/releases/download/v%s/google-java-format-%s-all-deps.jar" % (google_java_format_version, google_java_format_version),
            "https://github.com/google/google-java-format/releases/download/v%s/google-java-format-%s-all-deps.jar" % (google_java_format_version, google_java_format_version),
        ],
    )

    http_archive(
        name = "com_google_protobuf",
        sha256 = com_google_protobuf_sha256,
        strip_prefix = "protobuf-%s" % com_google_protobuf_version,
        urls = [
            "https://mirror.bazel.build/github.com/protocolbuffers/protobuf/archive/v%s.tar.gz" % com_google_protobuf_version,
            "https://github.com/protocolbuffers/protobuf/archive/v%s.tar.gz" % com_google_protobuf_version,
        ],
    )

    http_archive(
        name = "com_github_bazelbuild_buildtools",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/buildtools/archive/%s.zip" % com_github_bazelbuild_buildtools_version,
            "https://github.com/bazelbuild/buildtools/archive/%s.zip" % com_github_bazelbuild_buildtools_version,
        ],
        strip_prefix = "buildtools-%s" % com_github_bazelbuild_buildtools_version,
        sha256 = com_github_bazelbuild_buildtools_sha256,
    )
