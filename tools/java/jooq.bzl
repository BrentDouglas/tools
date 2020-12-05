
def _java_jooq_library_impl(ctx):
    template = ctx.file.config
    base = ctx.genfiles_dir.path
    config = ctx.actions.declare_file(base + "/jooq.xml")
    args = []
    classpath=""
    add=False
    for file in ctx.files._classpath:
        if add:
            classpath += ":"
        add=True
        classpath += file.path
    for file in ctx.files.deps:
        classpath += ":" + file.path
    command="""/usr/bin/env bash -c "
        cat {template} \
            | sed 's%SUB_URL%{url}%' \
            | sed 's%SUB_USER%{username}%' \
            | sed 's%SUB_PASSWORD%{password}%' \
            | sed 's%SUB_DIRECTORY%{target}%' \
            > {config} \
            && java -cp {classpath} org.jooq.codegen.GenerationTool {config} \
            && jar cf {jar_name} {target}
            " """.format(
                        jar_name=ctx.outputs.jar.path,
                        template=template.path,
                        config=config.path,
                        target=base + "/jooq",
                        classpath=classpath,
                        url=ctx.attr.url,
                        username=ctx.attr.username,
                        password=ctx.attr.password,
                    )
    ctx.actions.run_shell(
        inputs=[template, ctx.file.version] + ctx.files.deps + ctx.files._classpath,
        outputs=[config, ctx.outputs.jar],
        arguments=args,
        command=command
    )
    return struct(files = depset([ctx.outputs.jar]))


java_jooq_library = rule(
    implementation = _java_jooq_library_impl,
    attrs = {
        "_classpath": attr.label_list(default=[
            Label("@sql_m2//:org_jooq_jooq"),
            Label("@sql_m2//:org_jooq_jooq_codegen"),
            Label("@sql_m2//:org_jooq_jooq_meta"),
            Label("@sql_m2//:org_reactivestreams_reactive_streams"),
            Label("@sql_m2//:javax_xml_bind_jaxb_api"),
        ]),
        "config": attr.label(allow_single_file=True),
        "url": attr.string(),
        "username": attr.string(),
        "password": attr.string(),
        "deps": attr.label_list(),
        "version": attr.label(allow_single_file=True),
    },
    outputs = {
        "jar": "%{name}.srcjar"
    }
)