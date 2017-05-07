load("//tools/java:maven_jar.bzl", "maven_jar")

def undertow_repositories(
        undertow_version = "1.4.22.Final",
        xnio_version = "3.3.8.Final"):
    maven_jar(
        name = "javax_servlet",
        artifact = "org.jboss.spec.javax.servlet:jboss-servlet-api_3.1_spec:1.0.0.Final",
    )
    maven_jar(
        name = "org_jboss_logging_jboss_logging",
        artifact = "org.jboss.logging:jboss-logging:3.2.1.Final",
    )
    maven_jar(
        name = "io_undertow_undertow_core",
        artifact = "io.undertow:undertow-core:" + undertow_version,
    )
    maven_jar(
        name = "io_undertow_undertow_servlet",
        artifact = "io.undertow:undertow-servlet:" + undertow_version,
    )
    maven_jar(
        name = "org_jboss_xnio_xnio_api",
        artifact = "org.jboss.xnio:xnio-api:" + xnio_version,
    )
    maven_jar(
        name = "org_jboss_xnio_xnio_nio",
        artifact = "org.jboss.xnio:xnio-nio:" + xnio_version,
    )
