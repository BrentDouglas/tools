load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def nodejs_repositories(
        build_bazel_rules_nodejs_version = "3.0.0",
        build_bazel_rules_nodejs_sha256 = "6142e9586162b179fdd570a55e50d1332e7d9c030efd853453438d607569721d",
        io_bazel_rules_sass_version = "1.32.2",
        io_bazel_rules_sass_sha256 = "7c4c9d8ac252ccd3d116845151cfa9e576cf6ee787d91b3c7c63092c0218e7c2",
        io_bazel_rules_webtesting_version = "0.3.3",
        io_bazel_rules_webtesting_sha256 = "d7cee4275a55dc4996c392dab662c4f7da9c5199e12bc684bec350a9aadd9bdc"):
    http_archive(
        name = "build_bazel_rules_nodejs",
        sha256 = build_bazel_rules_nodejs_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_nodejs/releases/download/%s/rules_nodejs-%s.tar.gz" % (build_bazel_rules_nodejs_version, build_bazel_rules_nodejs_version),
            "https://github.com/bazelbuild/rules_nodejs/releases/download/%s/rules_nodejs-%s.tar.gz" % (build_bazel_rules_nodejs_version, build_bazel_rules_nodejs_version),
        ],
    )
    http_archive(
        name = "io_bazel_rules_sass",
        sha256 = io_bazel_rules_sass_sha256,
        strip_prefix = "rules_sass-%s" % io_bazel_rules_sass_version,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_sass/archive/%s.tar.gz" % io_bazel_rules_sass_version,
            "https://github.com/bazelbuild/rules_sass/archive/%s.tar.gz" % io_bazel_rules_sass_version,
        ],
    )
    http_archive(
        name = "io_bazel_rules_webtesting",
        sha256 = io_bazel_rules_webtesting_sha256,
        strip_prefix = "rules_webtesting-%s" % io_bazel_rules_webtesting_version,
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_webtesting/archive/%s.tar.gz" % io_bazel_rules_webtesting_version,
            "https://github.com/bazelbuild/rules_webtesting/archive/%s.tar.gz" % io_bazel_rules_webtesting_version,
        ],
    )
