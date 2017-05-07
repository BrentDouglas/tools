def _asciidoc_impl(ctx):
    dest = ctx.attr.dest if ctx.attr.dest else ctx.label.name

    main = [
        "asciidoctor",
        "-r asciidoctor-diagram",
        "-D %s" % dest,
    ]
    if ctx.attr._type == "pdf":
        main.append("-r asciidoctor-pdf")
        main.append("-b pdf")
    else:
        main.append("-b html5")

    for key in ctx.attr.attributes:
        main.append("-a %s=%s" % (key, ctx.attr.attributes[key]))

    if ctx.attr.imagesdir:
        main.append("-a imagesdir=%s" % ctx.attr.imagesdir)

    for file in ctx.files.srcs:
        main.append(file.path)

    command = [
        "export PATH",
        "p=$PWD",
        "TZ=UTC",
        "export TZ",
        " \\\n    ".join(main),
    ]

    if ctx.attr.imagesdir:
        for file in ctx.files.resources:
            command.append("cp %s %s" % (file.path, dest + "/" + ctx.attr.imagesdir))
    command.append("find %s -exec touch -t 198001010000 '{}' ';'" % dest)
    command.append("tar cf %s %s" % (ctx.outputs.tar.path, dest))

    cmd = " \\\n  && ".join(command)

    outs = [ctx.outputs.tar]
    ctx.actions.run_shell(
        inputs = ctx.files.srcs + ctx.files.resources,
        outputs = outs,
        command = cmd,
    )
    return struct(files = depset(outs))

doc_to_html = rule(
    implementation = _asciidoc_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "resources": attr.label_list(allow_files = True),
        "dest": attr.string(),
        "imagesdir": attr.string(),
        "attributes": attr.string_dict(),
        "_type": attr.string(default = "html5"),
    },
    outputs = {
        "tar": "%{name}.tar",
    },
)
"""Process a file with asciidoctor and output the results as html.

Args:
  srcs: The adoc files to compile.
  resources: Other files (themes, images, etc) that asciidoctor will use when
    compiling them.
  dest: The resulting name of the folder (and archive) containing the docs
    if not supplied the name of the label will be used.
  imagesdir:  A directory containing images that asciidoctor should look in.
    The contents of this director must be included in the "resources".
  attributes: Settings to pass to the asciidoctor CLI.
"""

doc_to_pdf = rule(
    implementation = _asciidoc_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "resources": attr.label_list(allow_files = True),
        "dest": attr.string(),
        "imagesdir": attr.string(),
        "attributes": attr.string_dict(),
        "_type": attr.string(default = "pdf"),
    },
    outputs = {
        "tar": "%{name}.tar",
    },
)
"""Process a file with asciidoctor and output the results as a PDF.

Args:
  srcs: The adoc files to compile.
  resources: Other files (themes, images, etc) that asciidoctor will use when
    compiling them.
  dest: The resulting name of the folder (and archive) containing the docs
    if not supplied the name of the label will be used.
  imagesdir:  A directory containing images that asciidoctor should look in.
    The contents of this director must be included in the "resources".
  attributes: Settings to pass to the asciidoctor CLI.
"""
