load("//tools/java:maven_jar.bzl", "maven_jar")

def devsrv_repositories(
        flyway_version = "5.2.1",
        getopt_version = "1.0.13"):
    maven_jar(
        name = "org_flywaydb_flyway_core",
        artifact = "org.flywaydb:flyway-core:" + flyway_version,
    )
    maven_jar(
        name = "gnu_getopt_java_getopt",
        artifact = "gnu.getopt:java-getopt:" + getopt_version,
    )
