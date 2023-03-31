load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def nodejs_repositories(
        build_bazel_rules_nodejs_version = "5.8.2",
        build_bazel_rules_nodejs_sha256 = "94070eff79305be05b7699207fbac5d2608054dd53e6109f7d00d923919ff45a",
        io_bazel_rules_sass_version = "1.60.0",
        io_bazel_rules_sass_sha256 = "4149d7d28e4b0d037b7359415945fa6a893bbf031a2c1a3f7c1c0f4c562cbbb5",
        io_bazel_rules_webtesting_version = "0.3.5",
        io_bazel_rules_webtesting_sha256 = "1399c98bbf15c210eb8e97f3b375322f28b8bf754480a2d86f88799c76663358"):
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
