load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//:defs.bzl", "maven_repositories")

def grpc_rules_repositories(
        rules_protobuf_version = "0.8.2",
        rules_grpc_version = "1.20.0"):
    http_archive(
        name = "org_pubref_rules_protobuf",
        sha256 = "03c452ab8845f91d0b55204c3f0263c6d53c9f802d1dfa865585aeafb7e97f01",
        strip_prefix = "rules_protobuf-%s" % rules_protobuf_version,
        urls = [
            "https://mirror.bazel.build/github.com/pubref/rules_protobuf/archive/v%s.zip" % rules_protobuf_version,
            "https://github.com/pubref/rules_protobuf/archive/v%s.zip" % rules_protobuf_version,
        ],
    )

    http_archive(
        name = "io_grpc_rules_grpc",
        sha256 = "8bcc85c479be97e1ae799baadc592cff245f9fca3bc82a6668ea3d2dce9e1089",
        strip_prefix = "grpc-java-%s" % rules_grpc_version,
        urls = [
            "https://mirror.bazel.build/github.com/grpc/grpc-java/archive/v%s.zip" % rules_grpc_version,
            "https://github.com/grpc/grpc-java/archive/v%s.zip" % rules_grpc_version,
        ],
    )

def grpc_repositories(
        grpc_version = "1.9.0",
        okhttp_version = "2.5.0",
        okio_version = "1.13.0",
        guava_version = "19.0",
        google_common_protos_version = "1.0.4",
        error_prone_annotations_version = "2.1.2",
        com_google_code_findbugs_jsr305_version = "3.0.2",
        instrumentation_api_version = "0.4.3",
        opencensus_version = "0.10.0"):
    maven_install(
        name = "grpc_m2",
        repositories = maven_repositories,
        fetch_sources = True,
        artifacts = [
            "io.grpc:grpc-auth:" + grpc_version,
            "io.grpc:grpc-core:" + grpc_version,
            "io.grpc:grpc-context:" + grpc_version,
            "io.grpc:grpc-grpclb:" + grpc_version,
            "io.grpc:grpc-netty:" + grpc_version,
            "io.grpc:grpc-netty-shaded:" + grpc_version,
            "io.grpc:grpc-okhttp:" + grpc_version,
            "io.grpc:grpc-protobuf:" + grpc_version,
            "io.grpc:grpc-protobuf-nano:" + grpc_version,
            "io.grpc:grpc-stub:" + grpc_version,
            "io.grpc:grpc-services:" + grpc_version,
            "io.grpc:protoc-gen-grpc-java:" + grpc_version + ":exe:windows-x86_64",
            "io.grpc:protoc-gen-grpc-java:" + grpc_version + ":exe:osx-x86_64",
            "io.grpc:protoc-gen-grpc-java:" + grpc_version + ":exe:linux-x86_64",
            "io.grpc:grpc-testing:" + grpc_version,
            "io.grpc:grpc-testing-proto:" + grpc_version,
            "io.grpc:grpc-testing-proto:" + grpc_version,
            "com.google.api.grpc:proto-google-common-protos:" + google_common_protos_version,
            "com.squareup.okhttp:okhttp:" + okhttp_version,
            "com.squareup.okio:okio:" + okio_version,
            "com.google.guava:guava:" + guava_version,
            "com.google.errorprone:error_prone_annotations:" + error_prone_annotations_version,
            "com.google.code.findbugs:jsr305:" + com_google_code_findbugs_jsr305_version,
            "com.google.instrumentation:instrumentation-api:" + instrumentation_api_version,
            "io.opencensus:opencensus-api:" + opencensus_version,
            "io.opencensus:opencensus-contrib-grpc-metrics:" + opencensus_version,
        ],
    )
