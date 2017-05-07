load("//tools/java:maven_jar.bzl", "maven_jar")

def dagger_repositories(
        dagger_version = "2.14.1",
        google_java_format_version = "1.4",
        guava_version = "23.3-jre",
        javac_shaded_version = "9-dev-r4023-3",
        javapoet_version = "1.8.0",
        javax_inject_version = "1",
        omit = []):
    if "dagger" not in omit:
        maven_jar(
            name = "com_google_dagger_dagger",
            artifact = "com.google.dagger:dagger:" + dagger_version,
        )
        maven_jar(
            name = "com_google_dagger_dagger_compiler",
            artifact = "com.google.dagger:dagger-compiler:" + dagger_version,
        )
        maven_jar(
            name = "com_google_dagger_dagger_producers",
            artifact = "com.google.dagger:dagger-producers:" + dagger_version,
        )
        maven_jar(
            name = "com_google_dagger_dagger_spi",
            artifact = "com.google.dagger:dagger-spi:" + dagger_version,
        )
    if "google_java_format" not in omit:
        maven_jar(
            name = "com_google_googlejavaformat_google_java_format",
            artifact = "com.google.googlejavaformat:google-java-format:" + google_java_format_version,
        )
    if "guava" not in omit:
        maven_jar(
            name = "com_google_guava_guava",
            artifact = "com.google.guava:guava:" + guava_version,
        )
    if "javac_shaded" not in omit:
        maven_jar(
            name = "com_google_errorprone_javac_shaded",
            artifact = "com.google.errorprone:javac-shaded:" + javac_shaded_version,
        )
    if "javapoet" not in omit:
        maven_jar(
            name = "com_squareup_javapoet",
            artifact = "com.squareup:javapoet:" + javapoet_version,
        )
    if "javax_inject" not in omit:
        maven_jar(
            name = "javax_inject",
            artifact = "javax.inject:javax.inject:" + javax_inject_version,
        )
