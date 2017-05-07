load("//tools/java:maven_jar.bzl", "maven_jar")

def jooq_repositories(
        jooq_version = "3.11.7"):
    maven_jar(
        name = "org_jooq_jooq",
        artifact = "org.jooq:jooq:" + jooq_version,
    )
    maven_jar(
        name = "org_jooq_jooq_codegen",
        artifact = "org.jooq:jooq-codegen:" + jooq_version,
    )
    maven_jar(
        name = "org_jooq_jooq_meta",
        artifact = "org.jooq:jooq-meta:" + jooq_version,
    )
