def _devserver_impl(ctx):
    hosts = ctx.attr.hosts
    script = ctx.path(ctx.attr._generate_certificate)
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
    ] + [
        "%s -H '%s'" % (script, host)
        for host in hosts
    ] + ["find ."])
    out = ctx.execute([ctx.which("bash"), "-c", cmd])
    if out.return_code:
        fail("Failed generating certificates: %s\n" % (out.stderr))

    files = []
    for host in hosts:
        files.extend([
            '"%s.cert",' % host,
            '"%s.keystore.jks",' % host,
            '"%s.keystore.pkcs12",' % host,
            '"%s.truststore",' % host,
        ])

    main_content = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "certs",
    srcs = [
        %s
    ],
)
java_binary(
    name = "devserver",
    main_class = "io.machinecode.tools.devsrv.Main",
    resource_jars = [
        "@io_machinecode_tools//src/main/java/io/machinecode/tools/devsrv:lib",
    ],
    runtime_deps = [
        "@gnu_getopt_java_getopt//jar",
        "@io_undertow_undertow_core//jar",
        "@io_undertow_undertow_servlet//jar",
        "@javax_servlet//jar",
        "@org_jboss_logging_jboss_logging//jar",
        "@org_jboss_xnio_xnio_api//jar",
        "@org_jboss_xnio_xnio_nio//jar",
    ],
    resources = [
        ":certs",
    ],
)
""" % ("\n        ".join(files))
    ctx.file(
        "BUILD.bazel",
        main_content,
        False,
    )

devserver = repository_rule(
    implementation = _devserver_impl,
    local = True,
    attrs = {
        "_generate_certificate": attr.label(default = Label("//tools/java:generate-certificate")),
        "hosts": attr.string_list(),
    },
)
"""Generate certificates to be used by the devserver
"""
