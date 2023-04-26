load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def distribution_repositories(
        bazel_distribution_version = "2bfd31bba555e2d8df5e95492269421a1c8a0f23",
        bazel_distribution_sha256 = "d50458d189b6bb7043db8ea4ddf2324452584c62e58732fdf3c2344f23c6ee9f",
        dependencies_version = "66596a14ec39921e04aa336af8439962d4ee0005",
        dependencies_sha256 = "ff0458d189b6bb7043db8ea4ddf2324452584c62e58732fdf3c2344f23c6ee9f",
        kotlin_version = "v1.7.1",
        kotlin_sha256 = "fd92a98bd8a8f0e1cdcb490b93f5acef1f1727ed992571232d33de42395ca9b3"):
    http_archive(
        name = "io_bazel_rules_kotlin",
        sha256 = kotlin_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_kotlin/releases/download/%s/rules_kotlin_release.tgz" % (kotlin_version),
            "https://github.com/bazelbuild/rules_kotlin/releases/download/%s/rules_kotlin_release.tgz" % (kotlin_version),
        ],
    )
    http_archive(
        name = "vaticle_dependencies",
        strip_prefix = "dependencies-%s" % bazel_distribution_version,
        sha256 = bazel_distribution_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/vaticle/dependencies/archive/%s.tar.gz" % (bazel_distribution_version),
            "https://github.com/vaticle/dependencies/archive/%s.tar.gz" % (bazel_distribution_version),
        ],
    )
    http_archive(
        name = "vaticle_bazel_distribution",
        strip_prefix = "bazel-distribution-%s" % bazel_distribution_version,
        sha256 = bazel_distribution_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/vaticle/bazel-distribution/archive/%s.tar.gz" % (bazel_distribution_version),
            "https://github.com/vaticle/bazel-distribution/archive/%s.tar.gz" % (bazel_distribution_version),
        ],
    )
