load("@build_bazel_rules_nodejs//:defs.bzl", "check_bazel_version", "node_repositories")

def nodejs_binary_repositories(
        node_version = "12.4.0",
        yarn_version = "1.17.2",
        bazel_version = "0.27.0"):
    check_bazel_version(bazel_version)

    node_repositories(
        node_repositories = {
            "%s-darwin_amd64" % node_version: (
                "node-v%s-darwin-x64.tar.gz" % node_version,
                "node-v%s-darwin-x64" % node_version,
                "aaff97d59cda775165ef966ae74e70f55f3267e86d735ed3740ae9bf1d40531e",
            ),
            "%s-linux_amd64" % node_version: (
                "node-v%s-linux-x64.tar.gz" % node_version,
                "node-v%s-linux-x64" % node_version,
                "9a16909157e68d4e409a73b008994ed05b4b6bc952b65ffa7fbc5abb973d31e9",
            ),
            "%s-windows_amd64" % node_version: (
                "node-v%s-win-x64.zip" % node_version,
                "node-v%s-win-x64" % node_version,
                "ec8623e2528a35d3219200308e7ed41e24d4f7cd96530a4e6ac2513e44f7fad1",
            ),
        },
        node_urls = [
            "https://mirror.bazel.build/nodejs.org/dist/v{version}/{filename}",
            "https://nodejs.org/dist/v{version}/{filename}",
        ],
        node_version = node_version,
        package_json = ["//:package.json"],
        yarn_repositories = {
            yarn_version: (
                "yarn-v%s.tar.gz" % yarn_version,
                "yarn-v%s" % yarn_version,
                "1cb4eb5b30adcb995198e4ff95f344d3404116b1d2bd77323a6f22dd52596fd7",
            ),
        },
        yarn_urls = [
            "https://mirror.bazel.build/github.com/yarnpkg/yarn/releases/download/v{version}/{filename}",
            "https://github.com/yarnpkg/yarn/releases/download/v{version}/{filename}",
        ],
        yarn_version = yarn_version,
    )
