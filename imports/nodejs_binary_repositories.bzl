load("@build_bazel_rules_nodejs//:defs.bzl", "check_bazel_version", "node_repositories")

def nodejs_binary_repositories(
        node_version = "11.9.0",
        yarn_version = "1.15.2",
        bazel_version = "0.24.0"):

    check_bazel_version(bazel_version)

    node_repositories(
        node_repositories = {
            "%s-darwin_amd64" % node_version: (
                "node-v%s-darwin-x64.tar.gz" % node_version,
                "node-v%s-darwin-x64" % node_version,
                "5d6b84d2b0fd6afee07c371bc815a9e4b6671b85bedcb38815310bd0f884d399",
            ),
            "%s-linux_amd64" % node_version: (
                "node-v%s-linux-x64.tar.gz" % node_version,
                "node-v%s-linux-x64" % node_version,
                "0e872c288724e7de72eaa89d1fbc29979a60cdc8c4c0bc1ea65339328bbaaf4c",
            ),
            "%s-windows_amd64" % node_version: (
                "node-v%s-win-x64.zip" % node_version,
                "node-v%s-win-x64" % node_version,
                "985e4edc758cb5f77f85cddda0155616b92f163b8d3842c542b1c8a395068499",
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
                "c4feca9ba5d6bf1e820e8828609d3de733edf0e4722d17ed7ce493ed39f61abd",
            ),
        },
        yarn_urls = [
            "https://mirror.bazel.build/github.com/yarnpkg/yarn/releases/download/v{version}/{filename}",
            "https://github.com/yarnpkg/yarn/releases/download/v{version}/{filename}",
        ],
        yarn_version = yarn_version,
    )
