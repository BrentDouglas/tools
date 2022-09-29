load("@build_bazel_rules_nodejs//:index.bzl", "node_repositories")

def nodejs_binary_repositories(
        node_version = "14.15.3",
        yarn_version = "1.22.4"):
    node_repositories(
        node_version = node_version,
        package_json = ["//:package.json"],
        yarn_version = yarn_version,
    )
