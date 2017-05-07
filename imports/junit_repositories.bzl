load("//tools/java:maven_jar.bzl", "maven_jar")

def junit_repositories(
        junit_version = "4.12",
        mockito_version = "1.10.19"):
    maven_jar(
        name = "junit_junit",
        artifact = "junit:junit:" + junit_version,
    )
    maven_jar(
        name = "org_mockito_mockito_all",
        artifact = "org.mockito:mockito-all:" + mockito_version,
    )
