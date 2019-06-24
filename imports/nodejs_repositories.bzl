load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def nodejs_repositories(
        build_bazel_rules_nodejs_version = "0.32.2",
        build_bazel_rules_nodejs_sha256 = "26eb280ceab96a282a13bdbc9840f402f7ac8002829a8696795a3cfb6df5555e",
        io_bazel_rules_sass_version = "86ca977cf2a8ed481859f83a286e164d07335116",
        io_bazel_rules_sass_sha256 = "4f05239080175a3f4efa8982d2b7775892d656bb47e8cf56914d5f9441fb5ea6",
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