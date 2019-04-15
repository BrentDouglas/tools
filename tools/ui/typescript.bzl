load(
    "//tools:util.bzl",
    "extract_file",
    "filter_filetypes",
    "get_debug_commands",
    "get_path",
    "get_path_of",
    "get_post_debug_commands",
    "is_any_jar",
    "is_archive",
    "is_tar",
    "is_tgz",
    "join_dict",
    "join_list",
    "list_file",
    "strip_base",
)
load("//tools:ui.bzl", "extract_all_modules", "extract_module", "jar_filetype")

def _typescript_config_impl(ctx, dts = []):
    """Write a tsconfig.json file to run tsc against.

    It handles src files of types .ts and .d.ts. It also handles .jar
    and .srcjar types containing .ts and .d.ts files.
    """
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts
    srcs = ctx.files.srcs
    types = ctx.attr.types
    jars = filter_filetypes(jar_filetype, srcs)
    pkg = ctx.label.package
    include = ctx.attr.include
    root_dirs = ctx.attr.root_dirs

    options = '        "rootDir": "%s",\n' % pkg
    for k in opts:
        options += '        "%s": %s,\n' % (k, opts[k])
    for k in sopts:
        options += '        "%s": "%s",\n' % (k, sopts[k])
    if root_dirs:
        options += '        "rootDirs": [\n'
        for idx, root_dir in enumerate(root_dirs):
            options += (" " if idx == 0 else ",") + '           "%s"\n' % root_dir

        #            options += ',           "%s/%s"\n' % (base, root_dir)
        #            options += ',           "%s/%s"\n' % (gen_base, root_dir)
        options += "        ]"
    type_list = ""
    for idx, type in enumerate(types):
        if idx == 0:
            type_list = '        "' + type + '"'
        else:
            type_list += ',\n        "' + type + '"'

    # Unfortunalely node can't deal with this if "files": [...] is too long so
    # were using include/exclude which 'could' end up with the wrong stuff being
    # compiled, but you would have to have included the wrong stuff in the
    # compilation step.
    if include:
        files = [
            '    "include": [',
        ] + ['        "%s"' % val if idx == 0 else ',        "%s"' % val for idx, val in enumerate(include)] + [
            "    ],",
        ]
    else:
        dir_srcs = [strip_base(file.path, base, gen_base) for file in srcs]
        dir_srcs.extend([strip_base(file.path, base, gen_base) for file in dts])
        files = [
            '    "files": [',
        ] + ['        "%s"' % val if idx == 0 else ',       "%s"' % val for idx, val in enumerate(dir_srcs)] + [
            "    ],",
        ]
    content = "\n".join([
        "{",
        '    "compilerOptions": {',
        options,
        "    },",
    ] + files + [
        '    "exclude": [',
        '        "node_modules",',
        '        "bazel-out"',
        "    ],",
        '    "types": [',
        type_list,
        "    ]",
        "}",
    ])
    cmd = " \\\n  && ".join([
        """export CONTENT='%s' """ % content,
        "mkdir -p $p/%s" % pkg,
        "true" if not jars else " \\\n  && ".join(["(cd $p/%s && jar xf $p/%s)" % (pkg, j.path) for j in jars]),
        """echo "${CONTENT}" > tsconfig.json""",
    ])
    return cmd

def _typescript_library_impl(ctx):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    pkg = ctx.label.package
    tsc = "%s node_modules/typescript/bin/tsc" % ctx.file._node.path
    dest = ctx.attr.dest
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    jars = filter_filetypes(jar_filetype, srcs)
    sopts = ctx.attr.string_opts
    opts = ctx.attr.opts

    in_all = []
    in_deps = []
    in_js = []
    in_js_map = []
    in_dts = []
    for dep in ctx.attr.deps:
        if hasattr(dep, "dts"):
            in_dts.extend(dep.dts.to_list())
            in_js.extend(dep.js.to_list())
            in_js_map.extend(dep.js_map.to_list())
            in_all.extend(dep.dts.to_list())
        else:
            in_deps.append(dep)
        in_all.extend(dep.files.to_list())

    outs = []
    out_js = []
    out_js_map = []
    out_dts = []

    is_tsd = opts.get("declaration") == "true"
    is_source_map = opts.get("sourceMap") == "true"
    out_jar = None
    out_dir = sopts.get("outDir")
    if out_dir:
        dest_dir = base + "/" + out_dir
    else:
        dest_dir = base + "/" + pkg
    is_preserve = sopts.get("jsx") == "preserve"
    if (not sopts.get("module") or sopts.get("module") in ["amd", "systemjs"]) and dest:
        out_file = ctx.new_file(dest)
        tsc += " --outFile %s" % out_file.path
        outs.append(out_file)
        out_js.append(out_file)
        if is_source_map:
            map = ctx.new_file(dest + ".map")
            outs.append(map)
            out_js_map.append(map)
        if is_tsd:
            dts = ctx.new_file(dest[:-3] + ".d.ts")
            outs.append(dts)
            out_dts.append(dts)
    else:
        tsc += " --outDir %s" % dest_dir
        for attr in ctx.attr.srcs:
            for file in attr.files:
                path = get_path(ctx, attr, file)
                if path.endswith(".ts") and not path.endswith(".d.ts"):
                    out = path[:-3]
                    out_file = ctx.new_file(out + ".js")
                    outs.append(out_file)
                    out_js.append(out_file)
                    if is_source_map:
                        map = ctx.new_file(out + ".map")
                        outs.append(map)
                        out_js_map.append(map)
                    if is_tsd:
                        dts = ctx.new_file(out + ".d.ts")
                        outs.append(dts)
                        out_dts.append(dts)
                elif path.endswith(".tsx"):
                    ext = ".jsx" if is_preserve else ".js"
                    out = path[:-4]
                    out_file = ctx.new_file(out + ext)
                    outs.append(out_file)
                    out_js.append(out_file)
                    if is_source_map:
                        map = ctx.new_file(out + ext + ".map")
                        outs.append(map)
                        out_js_map.append(map)
                    if is_tsd:
                        dts = ctx.new_file(out + ext + ".d.ts")
                        outs.append(dts)
                        out_dts.append(dts)
                if is_any_jar(path) and not out_jar:
                    out_jar = ctx.new_file(ctx.label.name + ".jar")
                    outs.append(out_jar)

    if ctx.attr.debug == "rule":
        debug_cmds = get_debug_commands(ctx, "tsconfig.json")
        debug_post_commands = get_post_debug_commands(ctx)
    else:
        debug_cmds = []
        debug_post_commands = []

    cmds = [
        "export PATH",
        "p=$PWD",
        "mkdir -p %s" % pkg,
        "(cp -r %s/* $p/ 2>/dev/null || true)" % base,
        "(cp -r %s/* $p/ 2>/dev/null || true)" % gen_base,
        extract_module(ctx.file._tsc.path),
    ] + extract_all_modules(ctx, in_deps) + [
        "export NODE_PATH=$p/node_modules",
        "true" if not jars else " \\\n  && ".join(["(cd $p/%s && jar xf $p/%s)" % (pkg, j.path) for j in jars]),
        _typescript_config_impl(ctx, in_dts),
    ] + debug_cmds + [
        tsc,
    ] + debug_post_commands

    # Strip any AMD path nonsense
    if sopts.get("module") == "amd":
        for out in outs:
            if is_any_jar(out.path):
                continue
            cmds.append("""perl -pi -e 's-(?:\.\./)*(?:node_modules/)?--g' %s""" % (out.path))

    # If we had input jars we need to generate the list of output files to stick into the output jar
    if out_jar:
        for j in jars:
            cmds.append("""(cd $p/%s && jar tf $p/%s | grep -v '\.d.ts$' | grep -E '\.ts$' | sed -E 's/\.ts$/.js/' ) >> classes.list""" % (pkg, j.path))
            if is_tsd:
                cmds.append("""(cd $p/%s && jar tf $p/%s | grep -v '\.d.ts$' | grep -E '\.ts$' | sed -E 's/\.ts$/.d.ts/' ) >> classes.list""" % (pkg, j.path))
            if is_source_map:
                cmds.append(""""(cd $p/%s && jar tf $p/%s | grep -v '\.d.ts$' | grep -E '\.ts$' | sed -E 's/\.ts$/.map/' ) >> classes.list""" % (pkg, j.path))
        cmds.append("cd $p/%s && jar cfM $p/%s @$p/classes.list" % (dest_dir, out_jar.path))

    cmd_file = ctx.new_file(ctx.label.name + "-tsc-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = " \\\n  && ".join(cmds),
    )
    ctx.actions.run_shell(
        inputs = [ctx.file._node, ctx.file._tsc, cmd_file] + ctx.files.srcs + in_all,
        outputs = outs,
        command = "bash %s" % cmd_file.path,
    )
    return struct(
        files = depset(outs),
        deps = depset(deps),
        dts = depset(out_dts),
        js = depset(out_js),
        js_map = depset(out_js_map),
    )

typescript_library = rule(
    implementation = _typescript_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".ts",
            ".tsx",
            ".d.ts",
            ".srcjar",
            ".jar",
        ]),
        "deps": attr.label_list(allow_files = True),
        "types": attr.string_list(),
        "include": attr.string_list(),
        "opts": attr.string_dict(),
        "root_dirs": attr.string_list(),
        "string_opts": attr.string_dict(),
        "debug": attr.string(),
        "dest": attr.string(),
        "_tsc": attr.label(
            default = Label("@typescript//pkg"),
            allow_single_file = True,
        ),
        "_node": attr.label(
            default = Label("@nodejs//:node"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
    },
)
"""Compile typescript files with tsc.

It handles src files of types .ts and .d.ts. It also handles .jar
and .srcjar types containing .ts and .d.ts files. It also handles
.tar.gz and .tgz files and assumed they are packaged as NPM modules.

Args:
  srcs: The typescript source files to compile. They may either be regular
    files or wrapped in a jar/srcjar container.
  deps: NPM dependencies for the compilation step (e.g. @types/lodash)
  types: A list of node module names from which tsc should load the types
    from. This means they need to have the "types" field set in package.json
  opts: Boolean options for tcs. They end up in the form
    "option": true. The values must be the strings "true" or
    "false" as they end up as json boolean primitives.
  string_opts: String options with an argument to pass to tcs. They in
    up in the form "option": "value". The values may be any string.
  dest: The filename to output to. Only works with AMD and SystemJS modules
"""

def _ts_compress_html_impl(ctx):
    """
    Compress HTML in TS files
    """
    srcs = ctx.files.srcs
    compress = ctx.file._compress
    base = ctx.bin_dir.path
    pkg = ctx.label.package

    files = [(x, ctx.new_file(strip_base(x.path, base, pkg))) for x in srcs]

    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
        ] + ["python3 %s -i %s -o %s" % (compress.path, x[0].path, x[1].path) for x in files],
    )
    outputs = [x[1] for x in files]
    cmd_file = ctx.new_file(ctx.label.name + "-ts-html-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
    )
    ctx.actions.run_shell(
        inputs = srcs + [cmd_file, compress],
        outputs = outputs,
        command = "bash %s" % cmd_file.path,
    )
    return struct(
        files = depset(outputs),
    )

ts_compress_html = rule(
    implementation = _ts_compress_html_impl,
    attrs = {
        "_compress": attr.label(
            default = Label("//tools/ui:compress-html"),
            allow_single_file = True,
        ),
        "srcs": attr.label_list(allow_files = [
            ".ts",
            ".tsx",
        ]),
    },
)

def _tslint_test_impl(ctx):
    base = ctx.bin_dir.path
    srcs = ctx.files.srcs
    deps = ctx.files.deps
    config = ctx.file.config
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts

    args = ""
    inputs = []
    if config:
        args += " -c %s" % config.path
        inputs.append(config)

    node = " ".join(
        ["%s node_modules/tslint/bin/tslint" % ctx.file._node.path] +
        [args] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts],
    )
    run = node + " \\\n    " + " \\\n    ".join([x.path for x in srcs])
    cmd = " \\\n  && ".join([
        "export PATH",
        "p=$PWD",
        extract_module(ctx.file._tslint.path),
        extract_module(ctx.file._typescript.path),
    ] + [extract_module(dep.path) if not dep.path.startswith(base) else extract_module(dep.path[len(base) + 1:]) for dep in deps] + [
        run,
    ])
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = cmd,
        is_executable = True,
    )
    files = [ctx.file._node, ctx.file._tslint, ctx.file._typescript, ctx.outputs.executable] + inputs + srcs + deps
    runfiles = ctx.runfiles(
        files = files,
        collect_data = True,
    )
    return struct(
        files = depset(files),
        runfiles = runfiles,
    )

tslint_test = rule(
    implementation = _tslint_test_impl,
    test = True,
    attrs = {
        "srcs": attr.label_list(allow_files = [
            ".js",
            ".ts",
        ]),
        "deps": attr.label_list(),
        "config": attr.label(allow_single_file = True),
        "opts": attr.string_list(),
        "string_opts": attr.string_dict(),
        "_tslint": attr.label(
            default = Label("@tslint//pkg"),
            allow_single_file = True,
        ),
        "_typescript": attr.label(
            default = Label("@typescript//pkg"),
            allow_single_file = True,
        ),
        "_node": attr.label(
            default = Label("@nodejs//:node"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
    },
)
"""Create a test using tslint.

Args:
  srcs: The files to be linted to run
  deps: NPM modules that are needed to run the linter
  config: The tslint.json file
  opts: Options to be passed on the command line that have no
    argument
  string_opts: Options to be passed on the command line that have an
    argument
"""
