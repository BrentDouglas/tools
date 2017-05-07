"""
Machinecode Build Tools
"""

workspace(name = "io_machinecode_tools")

bazel_version = "0.17.1"

rules_skylib_version = "8cecf885c8bf4c51e82fd6b50b9dd68d2c98f757"

rules_skydoc_version = "77e5399258f6d91417d23634fce97d73b40cf337"

rules_nodejs_version = "0.15.1"

rules_sass_version = "1.14.1"

#buildtools_version = "49a6c199e3fbf5d94534b2771868677d3f9c6de9"

#rules_typescript_version = "0.15.3"
rules_webtesting_version = "7e730b14fb5d2537ede28675eadad1e184c2f717"

rules_go_version = "0.13.0"

rules_protobuf_version = "0.8.2"

rules_grpc_version = "1.13.1"

node_version = "11.1.0"

yarn_version = "1.12.3"

# Archives

http_archive(
    name = "bazel_skylib",
    sha256 = "68ef2998919a92c2c9553f7a6b00a1d0615b57720a13239c0e51d0ded5aa452a",
    strip_prefix = "bazel-skylib-" + rules_skylib_version,
    urls = ["https://github.com/bazelbuild/bazel-skylib/archive/%s.tar.gz" % rules_skylib_version],
)

http_archive(
    name = "io_bazel_skydoc",
    sha256 = "1088233aa190d79ebaff712eae28adeb21bdc71d6378ae4ead2471405964ad14",
    strip_prefix = "skydoc-" + rules_skydoc_version,
    urls = ["https://github.com/bazelbuild/skydoc/archive/%s.tar.gz" % rules_skydoc_version],
)

http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "a0a91a2e0cee32e9304f1aeea9e6c1b611afba548058c5980217d44ee11e3dd7",
    strip_prefix = "rules_nodejs-%s" % rules_nodejs_version,
    urls = ["https://github.com/bazelbuild/rules_nodejs/archive/%s.zip" % rules_nodejs_version],
)

http_archive(
    name = "io_bazel_rules_sass",
    sha256 = "d8b89e47b05092a6eed3fa199f2de7cf671a4b9165d0bf38f12a0363dda928d3",
    strip_prefix = "rules_sass-%s" % rules_sass_version,
    url = "https://github.com/bazelbuild/rules_sass/archive/%s.zip" % rules_sass_version,
)

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
http_archive(
    name = "io_bazel_rules_webtesting",
    sha256 = "2bc82e8b751b49354db4c68de7602ce76c9d83a6f34e35ba48cc45430ecccaec",
    strip_prefix = "rules_webtesting-%s" % rules_webtesting_version,
    url = "https://github.com/bazelbuild/rules_webtesting/archive/%s.zip" % rules_webtesting_version,
)

http_archive(
    name = "io_bazel_rules_sass",
    sha256 = "d8b89e47b05092a6eed3fa199f2de7cf671a4b9165d0bf38f12a0363dda928d3",
    strip_prefix = "rules_sass-%s" % rules_sass_version,
    url = "https://github.com/bazelbuild/rules_sass/archive/%s.zip" % rules_sass_version,
)

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "ba79c532ac400cefd1859cbc8a9829346aa69e3b99482cd5a54432092cbc3933",
    url = "https://github.com/bazelbuild/rules_go/releases/download/%s/rules_go-%s.tar.gz" % (rules_go_version, rules_go_version),
)

http_archive(
    name = "org_pubref_rules_protobuf",
    sha256 = "03c452ab8845f91d0b55204c3f0263c6d53c9f802d1dfa865585aeafb7e97f01",
    strip_prefix = "rules_protobuf-%s" % rules_protobuf_version,
    urls = ["https://github.com/pubref/rules_protobuf/archive/v%s.zip" % rules_protobuf_version],
)

http_archive(
    name = "io_grpc_rules_grpc",
    sha256 = "8bcc85c479be97e1ae799baadc592cff245f9fca3bc82a6668ea3d2dce9e1099",
    strip_prefix = "grpc-java-%s" % rules_grpc_version,
    urls = ["https://github.com/grpc/grpc-java/archive/v%s.zip" % rules_grpc_version],
)

####################################
# Load and install our dependencies downloaded above.

load("@io_bazel_rules_go//go:def.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

load("@build_bazel_rules_nodejs//:defs.bzl", "check_bazel_version", "node_repositories", "yarn_install")

check_bazel_version(bazel_version)

node_repositories(
    node_repositories = {
        "%s-darwin_amd64" % node_version: (
            "node-v%s-darwin-x64.tar.gz" % node_version,
            "node-v%s-darwin-x64" % node_version,
            "5d6b84d2b0fd6afee07c371bc815a9e4b6671b85bedcb38815310bd0f884d3c8",
        ),
        "%s-linux_amd64" % node_version: (
            "node-v%s-linux-x64.tar.gz" % node_version,
            "node-v%s-linux-x64" % node_version,
            "52289a646a27511f5808290357798c7ebd4b5132a8fc3bf7d5bf53183b89c668",
        ),
        "%s-windows_amd64" % node_version: (
            "node-v%s-win-x64.zip" % node_version,
            "node-v%s-win-x64" % node_version,
            "985e4edc758cb5f77f85cddda0155616b92f163b8d3842c542b1c8a395068418",
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
            "02cd4b589ec22c4bdbd2bc5ebbfd99c5e99b07242ad68a539cb37896b93a24f2",
        ),
    },
    yarn_urls = [
        "https://mirror.bazel.build/github.com/yarnpkg/yarn/releases/download/v{version}/{filename}",
        "https://github.com/yarnpkg/yarn/releases/download/v{version}/{filename}",
    ],
    yarn_version = yarn_version,
)

yarn_install(
    name = "npm",
    package_json = "//:package.json",
    yarn_lock = "//:yarn.lock",
)

load("@io_bazel_rules_webtesting//web:repositories.bzl", "browser_repositories", "web_test_repositories")

web_test_repositories(
    omit_com_google_code_findbugs_jsr305 = True,
)

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
