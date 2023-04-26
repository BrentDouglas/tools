load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//:defs.bzl", "maven_repositories")

def checkstyle_repositories(
        antlr_antlr_version = "2.7.7",
        org_antlr_antlr4_runtime_version = "4.7.1",
        com_puppycrawl_tools_checkstyle_version = "8.14",
        commons_beanutils_commons_beanutils_version = "1.9.3",
        commons_cli_commons_cli_version = "1.4",
        commons_collections_commons_collections_version = "3.2.2",
        com_google_guava_guava_version = "26.0-jre",
        org_slf4j_slf4j_api_version = "1.7.7",
        org_slf4j_jcl_over_slf4j_version = "1.7.7"):
    maven_install(
        name = "checkstyle_m2",
        repositories = maven_repositories,
        fetch_sources = True,
        artifacts = [
            "antlr:antlr:" + antlr_antlr_version,
            "org.antlr:antlr4-runtime:" + org_antlr_antlr4_runtime_version,
            "com.puppycrawl.tools:checkstyle:" + com_puppycrawl_tools_checkstyle_version,
            "commons-beanutils:commons-beanutils:" + commons_beanutils_commons_beanutils_version,
            "commons-cli:commons-cli:" + commons_cli_commons_cli_version,
            "commons-collections:commons-collections:" + commons_collections_commons_collections_version,
            "com.google.guava:guava:" + com_google_guava_guava_version,
            "org.slf4j:slf4j-api:" + org_slf4j_slf4j_api_version,
            "org.slf4j:jcl-over-slf4j:" + org_slf4j_jcl_over_slf4j_version,
        ],
    )
