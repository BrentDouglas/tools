load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//:defs.bzl", "maven_repositories")

def devsrv_repositories(
        getopt_version = "1.0.13",
        undertow_version = "1.4.22.Final",
        xnio_version = "3.3.8.Final",
        java_servlet_version = "1.0.0.Final",
        jboss_logging_version = "3.2.1.Final"):
    maven_install(
        name = "devsrv_m2",
        repositories = maven_repositories,
        artifacts = [
            "gnu.getopt:java-getopt:" + getopt_version,
            "org.jboss.spec.javax.servlet:jboss-servlet-api_3.1_spec:" + java_servlet_version,
            "org.jboss.logging:jboss-logging:" + jboss_logging_version,
            "io.undertow:undertow-core:" + undertow_version,
            "io.undertow:undertow-servlet:" + undertow_version,
            "org.jboss.xnio:xnio-api:" + xnio_version,
            "org.jboss.xnio:xnio-nio:" + xnio_version,
        ],
    )
