def _devserver_certificates_impl(ctx):
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
filegroup(
    name = "certs",
    srcs = [
        %s
    ],
)""" % ("\n        ".join(files))

    return ctx.file(
        "BUILD.bazel",
        "\n".join([
            """package(default_visibility = ["//visibility:public"])""",
            main_content,
        ]),
        False,
    )

devserver_certificates = repository_rule(
    implementation = _devserver_certificates_impl,
    local = True,
    attrs = {
        "_generate_certificate": attr.label(default = Label("//tools/java:generate-certificate")),
        "hosts": attr.string_list(),
    },
)
"""Generate certificates to be used by the devserver
"""
