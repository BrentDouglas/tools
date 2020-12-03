load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//:defs.bzl", "maven_repositories")

def sql_repositories(
        getopt_version = "1.0.13",
        flyway_version = "6.0.4",
        jooq_version = "3.12.3",
        reactive_streams_version = "1.0.3"):
    maven_install(
        name = "sql_m2",
        repositories = maven_repositories,
        artifacts = [
            "gnu.getopt:java-getopt:" + getopt_version,
            "org.flywaydb:flyway-core:" + flyway_version,
            "org.jooq:jooq-codegen:" + jooq_version,
            "org.jooq:jooq-meta:" + jooq_version,
            "org.reactivestreams:reactive-streams:" + reactive_streams_version,
            "org.jooq:jooq:" + jooq_version,
        ],
    )
