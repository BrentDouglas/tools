load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def profiler_repositories(
        async_profiler_1_version = "1.8.2",
        async_profiler_1_sha256 = "5543acd94624847c58ba9912f70aca66d75eb2ea4cb03bee58b8f16c6b83707c",
        async_profiler_2_version = "2.0-b1",
        async_profiler_2_sha256 = "576d10c347fd5569b3d34ce3a1eb5165238ff65982c443e39b794e2ce645ed54"):
    http_archive(
        name = "async_profiler_2",
        strip_prefix = "async-profiler-%s-linux-x64" % async_profiler_2_version,
        sha256 = async_profiler_2_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/jvm-profiling-tools/async-profiler/releases/download/v%s/async-profiler-%s-linux-x64.tar.gz" % (async_profiler_2_version, async_profiler_2_version),
            "https://github.com/jvm-profiling-tools/async-profiler/releases/download/v%s/async-profiler-%s-linux-x64.tar.gz" % (async_profiler_2_version, async_profiler_2_version),
        ],
        build_file = "//imports:async_profiler.BUILD.bazel",
    )

    http_archive(
        name = "async_profiler_1",
        strip_prefix = "async-profiler-%s-linux-x64" % async_profiler_1_version,
        sha256 = async_profiler_1_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/jvm-profiling-tools/async-profiler/releases/download/v%s/async-profiler-%s-linux-x64.tar.gz" % (async_profiler_1_version, async_profiler_1_version),
            "https://github.com/jvm-profiling-tools/async-profiler/releases/download/v%s/async-profiler-%s-linux-x64.tar.gz" % (async_profiler_1_version, async_profiler_1_version),
        ],
        build_file = "//tools:async_profiler.BUILD.bazel",
    )