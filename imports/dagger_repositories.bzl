load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//:defs.bzl", "maven_repositories")

def dagger_repositories(
        dagger_version = "2.14.1",
        google_java_format_version = "1.4",
        guava_version = "23.3-jre",
        javac_shaded_version = "9-dev-r4023-3",
        javapoet_version = "1.8.0",
        javax_inject_version = "1"):
    maven_install(
        name = "dagger_m2",
        repositories = maven_repositories,
        artifacts = [
            "com.google.dagger:dagger:" + dagger_version,
            "com.google.dagger:dagger-compiler:" + dagger_version,
            "com.google.dagger:dagger-producers:" + dagger_version,
            "com.google.dagger:dagger-spi:" + dagger_version,
            "com.google.googlejavaformat:google-java-format:" + google_java_format_version,
            "com.google.guava:guava:" + guava_version,
            "com.google.errorprone:javac-shaded:" + javac_shaded_version,
            "com.squareup:javapoet:" + javapoet_version,
            "javax.inject:javax.inject:" + javax_inject_version,
        ],
    )
