"""
Machinecode Build Tools
"""

workspace(name = "io_machinecode_tools")

#buildtools_version = "49a6c199e3fbf5d94534b2771868677d3f9c6de9"

#rules_typescript_version = "0.15.3"

# Archives

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load("//imports:format_repositories.bzl", "format_repositories")

format_repositories()

load("//imports:skydoc_repositories.bzl", "skydoc_repositories")

skydoc_repositories()

load("//imports:go_repositories.bzl", "go_repositories")

go_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
gazelle_dependencies()

load("//imports:nodejs_repositories.bzl", "nodejs_repositories")

nodejs_repositories()

load("//imports:nodejs_binary_repositories.bzl", "nodejs_binary_repositories")

nodejs_binary_repositories()

# The Bazel buildtools repo contains tools like the BUILD file formatter, buildifier
# This commit matches the version of buildifier in angular/ngcontainer
# If you change this, also check if it matches the version in the angular/ngcontainer
# version in /.circleci/config.yml

#http_archive(
#    name = "com_github_bazelbuild_buildtools",
#    url = "https://github.com/bazelbuild/buildtools/archive/%s.zip" % buildtools_version,
#    strip_prefix = "buildtools-%s" % buildtools_version,
#    sha256 = "edf39af5fc257521e4af4c40829fffe8fba6d0ebff9f4dd69a6f8f1223ae047b",
#)
#http_archive(
#    name = "build_bazel_rules_typescript",
#    url = "https://github.com/bazelbuild/rules_typescript/archive/%s.zip" % rules_typescript_version,
#    strip_prefix = "rules_typescript-%s" % rules_typescript_version,
#    sha256 = "a2b26ac3fc13036011196063db1bf7f1eae81334449201dc28087ebfa3708c99",
#)

load("//imports:grpc_repositories.bzl", "grpc_rules_repositories")

grpc_rules_repositories()

####################################
# Load and install our dependencies downloaded above.

load("@build_bazel_rules_nodejs//:defs.bzl", "yarn_install")

yarn_install(
    name = "npm",
    package_json = "//:package.json",
    yarn_lock = "//:yarn.lock",
)

load("@io_bazel_rules_webtesting//web:repositories.bzl", "web_test_repositories")
load("@io_bazel_rules_webtesting//web/versioned:browsers-0.3.1.bzl", "browser_repositories")

web_test_repositories()

browser_repositories(
    chromium = True,
    firefox = True,
)

load("//tools/java:devserver.bzl", "devserver_certificates")

devserver_certificates(
    name = "io_machinecode_devserver_certificates",
    hosts = [
        "localhost",
        "0.0.0.0",
    ],
)

#load("@build_bazel_rules_typescript//:defs.bzl", "ts_setup_workspace", "check_rules_typescript_version")
#
#ts_setup_workspace()

load("@io_bazel_rules_sass//sass:sass_repositories.bzl", "sass_repositories")

sass_repositories()

load("@io_bazel_skydoc//skylark:skylark.bzl", "skydoc_repositories")

skydoc_repositories()

load("//imports:devsrv_repositories.bzl", "devsrv_repositories")

devsrv_repositories()

load("//imports:build_repositories.bzl", "build_repositories")

build_repositories()

load("//imports:grpc_repositories.bzl", "grpc_repositories")

grpc_repositories(omit = [
    "guava",
])

load("//imports:undertow_repositories.bzl", "undertow_repositories")

undertow_repositories()

load("//imports:dagger_repositories.bzl", "dagger_repositories")

dagger_repositories()

load("//imports:jooq_repositories.bzl", "jooq_repositories")

jooq_repositories()

load("//imports:junit_repositories.bzl", "junit_repositories")

junit_repositories()

load("//imports:npm_repositories.bzl", "npm_repositories")

npm_repositories()

load("//imports:jmh_repositories.bzl", "jmh_repositories")

jmh_repositories()

load("//imports:template_repositories.bzl", "template_repositories")

template_repositories()
