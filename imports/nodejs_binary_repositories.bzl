load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")
load("@rules_nodejs//nodejs:yarn_repositories.bzl", "yarn_repositories")

def nodejs_binary_repositories(
        node_version = "16.13.2",
        yarn_version = "1.22.17"):
    nodejs_register_toolchains(
        name = "nodejs",
        node_version = "16.13.2",
    )
    yarn_repositories(
        name = "yarn",
        yarn_version = "1.22.17",
    )
