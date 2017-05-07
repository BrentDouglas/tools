
def _add_classpath_impl(ctx):
    name = ctx.label.name
    in_jar = ctx.file.jar
    out_jar = ctx.outputs.jar
    deps = ctx.files.deps
    prefix = ctx.attr.prefix

    manifest = ""
    for line in ctx.attr.manifest:
      manifest += line + "\n"

    if deps:
      man_pref = "Class-Path: "
      for dep in deps:
        manifest += man_pref + prefix + dep.basename + "\n"
        man_pref = "  "

    command = " \\\n  && ".join([
      "export PATH",
      "cp %s %s" % (in_jar.path, out_jar.path),
      "echo '%s' > temp.mf" % (manifest),
      """iconv -f "$( locale charmap | tr [:lower:] [:upper:] )" -t UTF-8 temp.mf > MANIFEST.MF""",
      "jar umf MANIFEST.MF %s" % (out_jar.path),
    ])
    outs = [out_jar]
    ctx.action(
        inputs=[in_jar] + deps,
        outputs=outs,
        arguments=[],
        command=command
    )
    return struct(files = depset(outs))

add_classpath = rule(
    implementation = _add_classpath_impl,
    attrs = {
        "jar": attr.label(allow_single_file=True),
        "deps": attr.label_list(),
        "prefix": attr.string(),
        "manifest": attr.string_list(),
    },
    outputs = {
        "jar": "%{name}.jar"
    },
)
"""Repack a jar for deployment, adding the classpath to the manifest

Args:
  jar: The jar we want to edit the manifest of.
  deps: The jars we want to add to the classpath.
  prefix: A prefix to add to the dependency jars filename in
    the manifest. For example if they are all in a folder "lib"
    relative to the root jar, then this should be set to "lib/"
  manifest: Other attributes to add to the manifest.
"""