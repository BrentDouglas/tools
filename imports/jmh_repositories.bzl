load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//:defs.bzl", "maven_repositories")

def jmh_repositories(
        jmh_version = "1.36",
        jopt_version = "5.0.4",
        commons_math_version = "3.6.1",
        asm_version = "9.5"):
    maven_install(
        name = "jmh_m2",
        repositories = maven_repositories,
        artifacts = [
            "org.openjdk.jmh:jmh-core:" + jmh_version,
            "org.openjdk.jmh:jmh-generator-annprocess:" + jmh_version,
            "net.sf.jopt-simple:jopt-simple:" + jopt_version,
            "org.apache.commons:commons-math3:" + commons_math_version,
            "org.ow2.asm:asm:" + asm_version,
        ],
    )
