load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

def format_repositories(
        google_java_format_version = "1.9",
        google_java_format_sha256 = "1d98720a5984de85a822aa32a378eeacd4d17480d31cba6e730caae313466b97",
        com_github_bazelbuild_buildtools_version = "49a6c199e3fbf5d94534b2771868677d3f9c6de9",
        com_github_bazelbuild_buildtools_sha256 = "edf39af5fc257521e4af4c40829fffe8fba6d0ebff9f4dd69a6f8f1223ae047b"):
    http_jar(
        name = "google_java_format",
        sha256 = google_java_format_sha256,
        urls = [
            "https://repo1.maven.org/maven2/com/google/googlejavaformat/google-java-format/%s/google-java-format-%s-all-deps.jar" % (google_java_format_version, google_java_format_version),
            "https://mirror.bazel.build/github.com/google/google-java-format/releases/download/google-java-format-%s/google-java-format-%s-all-deps.jar" % (google_java_format_version, google_java_format_version),
            "https://github.com/google/google-java-format/releases/download/google-java-format-%s/google-java-format-%s-all-deps.jar" % (google_java_format_version, google_java_format_version),
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
