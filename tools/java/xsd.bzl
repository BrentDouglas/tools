
def _xsd_library_impl(ctx):
    name = ctx.label.name
    schema = ctx.file.schema
    command="""
        set -euo pipefail;
        mkdir -p {target} \
            && xjc -d {target} -p {package} {schema} \
            && jar cf {jar_name} -C {target} .
    """.format(
        jar_name=ctx.outputs.jar.path,
        schema=schema.path,
        package=ctx.attr.package,
        target=name,
    )
    outs = [ctx.outputs.jar]
    ctx.action(
        inputs=[schema],
        outputs=outs,
        arguments=[],
        command=command
    )
    return struct(files = depset(outs))

xsd_library = rule(
    implementation = _xsd_library_impl,
    output_to_genfiles = True,
    attrs = {
        "schema": attr.label(allow_single_file=True),
        "package": attr.string(),
    },
    outputs = {
        "jar": "%{name}.srcjar"
    },
)
"""Generate code from an xsd using java's xjc tool.

Args:
  schema: The xsd schema to build the java files from.
  package: The package the output java files should be in.
"""