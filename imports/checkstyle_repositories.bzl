load("//tools/java:maven_jar.bzl", "maven_jar")

def checkstyle_repositories(
        antlr_antlr_version = "2.7.7",
        org_antlr_antlr4_runtime_version = "4.7.1",
        com_puppycrawl_tools_checkstyle_version = "8.14",
        commons_beanutils_commons_beanutils_version = "1.9.3",
        commons_cli_commons_cli_version = "1.4",
        commons_collections_commons_collections_version = "3.2.2",
        com_google_guava_guava_version = "26.0-jre",
        org_slf4j_slf4j_api_version = "1.7.7",
        org_slf4j_slf4j_jcl_version = "1.7.7",
        omit = []):
    if not "antlr_antlr" in omit:
        maven_jar(
            name = "antlr_antlr",
            attach_source = False,
            artifact = "antlr:antlr:" + antlr_antlr_version,
        )
    if not "org_antlr_antlr4_runtime" in omit:
        maven_jar(
            name = "org_antlr_antlr4_runtime",
            artifact = "org.antlr:antlr4-runtime:" + org_antlr_antlr4_runtime_version,
        )
    if not "com_puppycrawl_tools_checkstyle" in omit:
        maven_jar(
            name = "com_puppycrawl_tools_checkstyle",
            artifact = "com.puppycrawl.tools:checkstyle:" + com_puppycrawl_tools_checkstyle_version,
        )
    if not "commons_beanutils_commons_beanutils" in omit:
        maven_jar(
            name = "commons_beanutils_commons_beanutils",
            artifact = "commons-beanutils:commons-beanutils:" + commons_beanutils_commons_beanutils_version,
        )
    if not "commons_cli_commons_cli" in omit:
        maven_jar(
            name = "commons_cli_commons_cli",
            artifact = "commons-cli:commons-cli:" + commons_cli_commons_cli_version,
        )
    if not "commons_collections_commons_collections" in omit:
        maven_jar(
            name = "commons_collections_commons_collections",
            artifact = "commons-collections:commons-collections:" + commons_collections_commons_collections_version,
        )
    if not "com_google_guava_guava" in omit:
        maven_jar(
            name = "com_google_guava_guava",
            artifact = "com.google.guava:guava:" + com_google_guava_guava_version,
        )
    if not "org_slf4j_slf4j_api" in omit:
        maven_jar(
            name = "org_slf4j_slf4j_api",
            artifact = "org.slf4j:slf4j-api:" + org_slf4j_slf4j_api_version,
        )
    if not "org_slf4j_slf4j_jcl" in omit:
        maven_jar(
            name = "org_slf4j_slf4j_jcl",
            artifact = "org.slf4j:jcl-over-slf4j:" + org_slf4j_slf4j_jcl_version,
        )
