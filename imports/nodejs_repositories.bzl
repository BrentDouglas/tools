load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def nodejs_repositories(
        build_bazel_rules_nodejs_version = "0.27.12",
        build_bazel_rules_nodejs_sha256 = "c51307d3362274b486525fa18e25662dbf2aa76487f00503a9281afd066aef1a",
        io_bazel_rules_sass_version = "1.18.0",
        io_bazel_rules_sass_sha256 = "da2a23f33154e546022608802f96e248d01dcd23f24acbbfd17cf8beda8b13a4",
        io_bazel_rules_webtesting_version = "0.3.1",
        io_bazel_rules_webtesting_sha256 = "d587ac746569703ae37617e4cefe22ea191f7b34ad13199729f5f270f77069aa"):

    http_archive(
        name = "build_bazel_rules_nodejs",
        sha256 = build_bazel_rules_nodejs_sha256,
        strip_prefix = "rules_nodejs-%s" % build_bazel_rules_nodejs_version,
        urls = ["https://github.com/bazelbuild/rules_nodejs/archive/%s.zip" % build_bazel_rules_nodejs_version],
    )
    http_archive(
        name = "io_bazel_rules_sass",
        sha256 = io_bazel_rules_sass_sha256,
        strip_prefix = "rules_sass-%s" % io_bazel_rules_sass_version,
        urls = ["https://github.com/bazelbuild/rules_sass/archive/%s.zip" % io_bazel_rules_sass_version],
    )
    http_archive(
        name = "io_bazel_rules_webtesting",
        sha256 = io_bazel_rules_webtesting_sha256,
        strip_prefix = "rules_webtesting-%s" % io_bazel_rules_webtesting_version,
        url = "https://github.com/bazelbuild/rules_webtesting/archive/%s.zip" % io_bazel_rules_webtesting_version,
    )