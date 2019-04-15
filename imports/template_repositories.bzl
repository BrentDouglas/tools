load("//tools/java:maven_jar.bzl", "maven_jar")

def template_repositories(
        st_version = "4.1",
        getopt_version = "1.0.13",
        snakeyaml_version = "1.16"):
    maven_jar(
        name = "org_antlr_st4",
        artifact = "org.antlr:ST4:" + st_version,
    )
    maven_jar(
        name = "gnu_getopt_java_getopt",
        artifact = "gnu.getopt:java-getopt:" + getopt_version,
    )
    maven_jar(
        name = "org_yaml_snakeyaml",
        artifact = "org.yaml:snakeyaml:" + snakeyaml_version,
    )
