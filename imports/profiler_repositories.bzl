load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def profiler_repositories(
        async_profiler_version = "2.9",
        async_profiler_sha256 = "b9a094bc480f233f72141b7793c098800054438e0e6cfe5b7f2fe13ef4ad11f0"):
    http_archive(
        name = "async_profiler",
        strip_prefix = "async-profiler-%s-linux-x64" % async_profiler_version,
        sha256 = async_profiler_sha256,
        urls = [
            "https://mirror.bazel.build/github.com/jvm-profiling-tools/async-profiler/releases/download/v%s/async-profiler-%s-linux-x64.tar.gz" % (async_profiler_version, async_profiler_version),
            "https://github.com/jvm-profiling-tools/async-profiler/releases/download/v%s/async-profiler-%s-linux-x64.tar.gz" % (async_profiler_version, async_profiler_version),
        ],
        build_file = "@io_machinecode_tools//imports:async_profiler.BUILD.bazel",
    )
