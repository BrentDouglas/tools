load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//:defs.bzl", "maven_repositories")

def template_repositories(
        st_version = "4.1",
        getopt_version = "1.0.13",
        snakeyaml_version = "1.16"):
    maven_install(
        name = "template_m2",
        repositories = maven_repositories,
        artifacts = [
            "gnu.getopt:java-getopt:" + getopt_version,
            "org.yaml:snakeyaml:" + snakeyaml_version,
            "org.antlr:ST4:" + st_version,
        ],
    )
