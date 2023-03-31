load("@io_machinecode_tools//tools/db:flyway.bzl", _flyway_after_migrate = "flyway_after_migrate", _flyway_clean = "flyway_clean", _flyway_migrate = "flyway_migrate")
load("@io_machinecode_tools//tools/java:benchmark.bzl", _benchmark_library = "benchmark_library")
#load("@io_machinecode_tools//tools/java:java_filegroup.bzl", "java_filegroup")

flyway_clean = _flyway_clean
flyway_migrate = _flyway_migrate
flyway_after_migrate = _flyway_after_migrate
benchmark_library = _benchmark_library
