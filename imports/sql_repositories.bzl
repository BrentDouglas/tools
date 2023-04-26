load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//:defs.bzl", "maven_repositories")

def sql_repositories(
        getopt_version = "1.0.13",
        flyway_version = "7.3.1",
        jooq_version = "3.14.4",
        reactive_streams_version = "1.0.3",
        jaxb_version = "2.3.1"):
    maven_install(
        name = "sql_m2",
        repositories = maven_repositories,
        fetch_sources = True,
        artifacts = [
            "gnu.getopt:java-getopt:" + getopt_version,
            "org.flywaydb:flyway-core:" + flyway_version,
            "org.jooq:jooq-codegen:" + jooq_version,
            "org.jooq:jooq-meta:" + jooq_version,
            "org.reactivestreams:reactive-streams:" + reactive_streams_version,
            "org.jooq:jooq:" + jooq_version,
            "javax.xml.bind:jaxb-api:" + jaxb_version,
        ],
    )
