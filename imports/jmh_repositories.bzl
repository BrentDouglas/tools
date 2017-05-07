load("//tools/java:maven_jar.bzl", "maven_jar")

def jmh_repositories(
        jmh_version = "1.21",
        jopt_version = "4.6",
        commons_math_version = "3.2"):
    maven_jar(
        name = "org_openjdk_jmh_jmh_core",
        artifact = "org.openjdk.jmh:jmh-core:" + jmh_version,
    )
    maven_jar(
        name = "org_openjdk_jmh_jmh_generator_annprocess",
        artifact = "org.openjdk.jmh:jmh-generator-annprocess:" + jmh_version,
    )
    maven_jar(
        name = "net_sf_jopt_simple_jopt_simple",
        artifact = "net.sf.jopt-simple:jopt-simple:" + jopt_version,
    )
    maven_jar(
        name = "org_apache_commons_commons_math3",
        artifact = "org.apache.commons:commons-math3:" + commons_math_version,
    )
