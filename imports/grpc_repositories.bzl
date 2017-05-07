load("//tools/java:maven_jar.bzl", "maven_jar")

def grpc_repositories(
        grpc_version = "1.9.0",
        okhttp_version = "2.5.0",
        okio_version = "1.13.0",
        guava_version = "19.0",
        google_common_protos_version = "1.0.4",
        error_prone_annotations_version = "2.1.2",
        com_google_code_findbugs_jsr305_version = "3.0.2",
        instrumentation_api_version = "0.4.3",
        opencensus_version = "0.10.0",
        omit = []):
    if "grpc" not in omit:
        maven_jar(
            name = "io_grpc_grpc_auth",
            artifact = "io.grpc:grpc-auth:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_core",
            artifact = "io.grpc:grpc-core:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_context",
            artifact = "io.grpc:grpc-context:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_grpclb",
            artifact = "io.grpc:grpc-grpclb:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_netty",
            artifact = "io.grpc:grpc-netty:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_netty_shaded",
            artifact = "io.grpc:grpc-netty-shaded:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_okhttp",
            artifact = "io.grpc:grpc-okhttp:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_protobuf",
            artifact = "io.grpc:grpc-protobuf:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_protobuf_nano",
            artifact = "io.grpc:grpc-protobuf-nano:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_stub",
            artifact = "io.grpc:grpc-stub:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_services",
            artifact = "io.grpc:grpc-services:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_protoc_gen_grpc_java_windows",
            artifact = "io.grpc:protoc-gen-grpc-java:" + grpc_version + ":exe:windows-x86_64",
            attach_source = False,
        )
        maven_jar(
            name = "io_grpc_protoc_gen_grpc_java_osx",
            artifact = "io.grpc:protoc-gen-grpc-java:" + grpc_version + ":exe:osx-x86_64",
            attach_source = False,
        )
        maven_jar(
            name = "io_grpc_protoc_gen_grpc_java_linux",
            artifact = "io.grpc:protoc-gen-grpc-java:" + grpc_version + ":exe:linux-x86_64",
            attach_source = False,
        )

        maven_jar(
            name = "io_grpc_grpc_testing",
            artifact = "io.grpc:grpc-testing:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_testing_proto",
            artifact = "io.grpc:grpc-testing-proto:" + grpc_version,
        )
        maven_jar(
            name = "io_grpc_grpc_testing_proto",
            artifact = "io.grpc:grpc-testing-proto:" + grpc_version,
        )
    if "google_common_protos" not in omit:
        maven_jar(
            name = "com_google_api_grpc_proto_google_common_protos",
            artifact = "com.google.api.grpc:proto-google-common-protos:" + google_common_protos_version,
        )
    if "okhttp" not in omit:
        maven_jar(
            name = "com_squareup_okhttp",
            artifact = "com.squareup.okhttp:okhttp:" + okhttp_version,
        )
    if "okio" not in omit:
        maven_jar(
            name = "com_squareup_okio",
            artifact = "com.squareup.okio:okio:" + okio_version,
        )
    if "guava" not in omit:
        maven_jar(
            name = "com_google_guava_guava",
            artifact = "com.google.guava:guava:" + guava_version,
        )
    if "error_prone_annotations" not in omit:
        maven_jar(
            name = "com_google_errorprone_error_prone_annotations",
            artifact = "com.google.errorprone:error_prone_annotations:" + error_prone_annotations_version,
        )
    if "com_google_code_findbugs_jsr305" not in omit:
        maven_jar(
            name = "com_google_code_findbugs_jsr305",
            artifact = "com.google.code.findbugs:jsr305:" + com_google_code_findbugs_jsr305_version,
        )
    if "instrumentation_api" not in omit:
        maven_jar(
            name = "com_google_instrumentation_instrumentation_api",
            artifact = "com.google.instrumentation:instrumentation-api:" + instrumentation_api_version,
        )
    if "opencensus" not in omit:
        maven_jar(
            name = "io_opencensus_opencensus_api",
            artifact = "io.opencensus:opencensus-api:" + opencensus_version,
        )
        maven_jar(
            name = "io_opencensus_opencensus_contrib_grpc_metrics",
            artifact = "io.opencensus:opencensus-contrib-grpc-metrics:" + opencensus_version,
        )
