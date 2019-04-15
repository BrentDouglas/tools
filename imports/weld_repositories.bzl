load("//tools/java:maven_jar.bzl", "maven_jar")

def weld_repositories(
        javax_enterprise_version = "2.0.SP1",
        javax_interceptor_version = "1.2.2",
        weld_version = "3.0.5.Final",
        weld_api_version = "3.0.SP4",
        jandex_version = "2.0.3.Final",
        classfilewriter_version = "1.2.3.Final",
        weld_junit_version = "1.3.1.Final",
        javax_inject_version = "1",
        omit = []):
    if "javax_enterprise" not in omit:
        maven_jar(
            name = "javax_enterprise",
            artifact = "javax.enterprise:cdi-api:" + javax_enterprise_version,
        )
    if "javax_interceptor" not in omit:
        maven_jar(
            name = "javax_interceptor",
            artifact = "javax.interceptor:javax.interceptor-api:" + javax_interceptor_version,
        )
    if "jandex" not in omit:
        maven_jar(
            name = "org_jboss_jandex",
            artifact = "org.jboss:jandex:" + jandex_version,
        )
    if "weld_junit" not in omit:
        maven_jar(
            name = "org_jboss_weld_weld_junit_common",
            artifact = "org.jboss.weld:weld-junit-common:" + weld_junit_version,
        )
        maven_jar(
            name = "org_jboss_weld_weld_junit4",
            artifact = "org.jboss.weld:weld-junit4:" + weld_junit_version,
        )
    if "weld" not in omit:
        maven_jar(
            name = "org_jboss_weld_weld_api",
            artifact = "org.jboss.weld:weld-api:" + weld_api_version,
        )
        maven_jar(
            name = "org_jboss_weld_weld_spi",
            artifact = "org.jboss.weld:weld-spi:" + weld_api_version,
        )
        maven_jar(
            name = "org_jboss_weld_weld_core_impl",
            artifact = "org.jboss.weld:weld-core-impl:" + weld_version,
        )
        maven_jar(
            name = "org_jboss_weld_se_weld_se_core",
            artifact = "org.jboss.weld.se:weld-se-core:" + weld_version,
        )
        maven_jar(
            name = "org_jboss_weld_environment_weld_environment_common",
            artifact = "org.jboss.weld.environment:weld-environment-common:" + weld_version,
        )
        maven_jar(
            name = "org_jboss_weld_probe_weld_probe_core",
            artifact = "org.jboss.weld.probe:weld-probe-core:" + weld_version,
        )
        maven_jar(
            name = "org_jboss_classfilewriter_jboss_classfilewriter",
            artifact = "org.jboss.classfilewriter:jboss-classfilewriter:" + classfilewriter_version,
        )
#                    <groupId>org.jboss.spec.javax.annotation:jboss-annotations-api_1.3_spec</artifactId>
#                    <groupId>org.jboss.spec.javax.el:jboss-el-api_3.0_spec</artifactId>
#                    <groupId>org.jboss.spec.javax.interceptorjboss-interceptors-api_1.2_spec</artifactId>
    if "javax_inject" not in omit:
        maven_jar(
            name = "javax_inject",
            artifact = "javax.inject:javax.inject:" + javax_inject_version,
        )
