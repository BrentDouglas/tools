load(
    "//tools:util.bzl",
    "extract_file",
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

js_filetype = [".js"]
css_filetype = [".css"]
dts_filetype = [".d.ts"]
jar_filetype = [".srcjar", ".jar"]
tar_filetype = [".tar", ".tgz", ".tar.gz"]
ts_filetype = [".ts", ".d.ts"]

def extract_module(path):
    if is_any_jar(path):
        extract = "jar xf $p/%s" % (path)
    elif is_tgz(path):
        extract = "cat $p/%s | tar zxf -" % (path)
    else:
        extract = "cat $p/%s | tar xf -" % (path)
    return " \\\n  && ".join([
        "mkdir -p $p/node_modules",
        "cd $p/node_modules",
        extract,
        "cd $p",
    ])

def extract_all_modules(ctx, deps):
    ret = []
    for dep in deps:
        for file in dep.files.to_list():
            ret.append(extract_module(file.path))
    return ret

def _process_tuple(ctx, paths, outputs, cmds, dir):
    vals = paths[dir]
    if not len(vals):
        return
    js = ctx.actions.declare_file(dir + "export.js")
    dts = ctx.actions.declare_file(dir + "export.d.ts")
    outputs.append(js)
    outputs.append(dts)

    for val in vals:
        path = val[:val.index(".")]
        cmds.append("""echo 'export * from "./%s";' >> %s""" % (path, js.path))
        cmds.append("""echo 'export * from "./%s";' >> %s""" % (path, dts.path))

def _export_packages_impl(ctx):
    pkg = ctx.label.package
    root = ctx.attr.root
    packages = ctx.attr.packages
    srcs = ctx.attr.srcs
    export_root = ctx.attr.export_all_from_root
    export_all_packages = ctx.attr.export_all_packages
    if export_all_packages:
        tmp = dict()
        packages = []
        for src in srcs:
            for file in src.files:
                path = get_path_of(ctx, src, file.dirname)
                if path == root:
                    continue
                tmp[path] = True
        for key in tmp:
            packages.append(key + "/")

    paths = dict()
    if export_root:
        paths[root] = []
    for package in packages:
        paths[package] = []

    for src in srcs:
        for file in src.files:
            path = get_path(ctx, src, file)
            if is_archive(path):
                pass
            if export_root and path.startswith(root):
                paths[root].append(path[len(root):])
            if path == root:
                continue
            for package in packages:
                if path.startswith(package):
                    paths[package].append(path[len(package):])

    outputs = []
    cmds = []
    for package in packages:
        for val in paths[package]:
            path = val[:val.index(".")]
    for val in paths[root]:
        path = val[:val.index(".")]
    if export_root:
        _process_tuple(ctx, paths, outputs, cmds, root)
    for package in packages:
        _process_tuple(ctx, paths, outputs, cmds, package)

    cmd_file = ctx.actions.declare_file(ctx.label.name + "-exports-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = " \\\n  && ".join(cmds),
    )
    ctx.actions.run_shell(
        inputs = [cmd_file] + ctx.files.srcs,
        outputs = outputs,
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outputs))

export_packages = rule(
    implementation = _export_packages_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".ts"]),
        "root": attr.string(default = ""),
        "packages": attr.string_list(),
        "export_all_from_root": attr.bool(default = True),
        "export_all_packages": attr.bool(default = False),
    },
)
"""Generate index files for each of the packages we want to have in an npm module

Args:
  srcs: The files to export.
  root: The root package.
  packages: The packages that we want to export. If export_root is False
    but you still want to create a package from the root package
    you must add the empty string ("") to this package.
  export_all_from_root: When this is true, the root package will export all subpackages
    as well as its own files.
  export_all_packages: When this is true, all directories will be treated as packages
    and the "packages" attribute will be ignored.
"""

def _pkg_app_impl(ctx):
    assemble = ctx.file._assemble
    js = ctx.files.js
    css = ctx.files.css
    index = ctx.file.index_html
    sw = ctx.file._service_worker
    hash = "-H" if ctx.attr.hash else ""

    mv_html = [" \\\n    ".join([
        "/usr/bin/env python3 %s" % assemble.path,
        hash,
        """-D "$p/tar/" """,
    ] + ["""-j "%s" """ % x.path for x in js] + [
    ] + ["""-c "%s" """ % x.path for x in css] + [
        """-i "%s" """ % index.path,
        """-o "$p/tar/index.html" """,
    ])]
    for file in ctx.files.html:
        mv_html += [
            """cp "%s" "$p/tar/%s" """ % (file.path, file.basename),
        ]
    extract_deps = []
    for file in ctx.files.deps:
        extract_deps += [
            """tar -C "$p/tar/" -xf "%s" """ % (file.path),
        ]
    mv_img = []
    for i in range(0, len(ctx.attr.img)):
        attr = ctx.attr.img[i]
        for file in attr.files.to_list():
            path = get_path(ctx, attr, file)
            if path.startswith("img/"):
                path = path[len("img/"):]
            mv_img.append("mkdir -p $(dirname $p/tar/img/%s) && cp %s $p/tar/img/%s" % (path, file.path, path))
    mv_data = []
    for i in range(0, len(ctx.attr.data)):
        attr = ctx.attr.data[i]
        for file in attr.files.to_list():
            path = get_path(ctx, attr, file)
            mv_data.append("mkdir -p $(dirname $p/tar/%s) && cp %s $p/tar/%s" % (path, file.path, path))
    mv_icons = ["cp %s $p/tar/icons/%s" % (file.path, file.basename) for file in ctx.files.icons]
    service_worker = [] if not ctx.attr.service_worker else [
        """export FILES="$( ( cd $p/tar/ && find -type f | sort | xargs shasum | grep -v %s | awk '{print "[" "\\"" $1 "\\"" "," "\\"" $2 "\\"" "]"}' | tr '\\n' ',' ) )" """ % sw.basename,
        """export SHA="$( ( cd $p/tar/ && find -type f | sort | shasum | cut -d' ' -f1 ) )" """,
        """export CONTENT="$(cat %s | sed "s/TEMPLATE_VERSION/$SHA/")" """ % (sw.path),
        """echo "${CONTENT/"TEMPLATE_FILES"/$FILES}" > $p/tar/%s""" % (ctx.attr.service_worker),
    ]

    cmd = " \\\n  && ".join(
        [
            "export PATH",
            "p=$PWD",
            "mkdir -p $p/tar/img $p/tar/icons",
        ] +
        extract_deps +
        mv_html +
        mv_img +
        mv_data +
        mv_icons +
        service_worker +
        ['if [ $(uname) == "Darwin" ] ; then export TAR_LINK_OPT="L" else export TAR_LINK_OPT="H"; fi'] +
        ['( cd $p/tar/ && tar "cf${TAR_LINK_OPT}" - . > $p/%s )' % ctx.outputs.tar.path],
    )
    outs = [ctx.outputs.tar]
    cmd_file = ctx.actions.declare_file(ctx.label.name + "-pkg-app-cmd")
    ctx.actions.write(
        output = cmd_file,
        content = cmd,
    )
    ctx.actions.run_shell(
        inputs = js + css + [cmd_file, assemble, index, sw] + ctx.files.deps + ctx.files.icons + ctx.files.html + ctx.files.img + ctx.files.data,
        outputs = outs,
        command = "bash %s" % cmd_file.path,
    )
    return struct(files = depset(outs))

pkg_app = rule(
    implementation = _pkg_app_impl,
    attrs = {
        "index_html": attr.label(allow_single_file = [".html"]),
        "html": attr.label_list(allow_files = [".html"]),
        "js": attr.label_list(mandatory = False, allow_files = [".js", ".js.map"]),
        "css": attr.label_list(mandatory = False, allow_files = [".css", ".js.map"]),
        "icons": attr.label_list(mandatory = False, allow_files = [".woff", ".eot", ".ttf", ".svf"]),
        "img": attr.label_list(allow_files = [".png", ".svg", ".jpg", ".jpeg"]),
        "data": attr.label_list(allow_files = True),
        "hash": attr.bool(),
        "deps": attr.label_list(allow_files = [".tar"]),
        "service_worker": attr.string(mandatory = False),
        "_service_worker": attr.label(
            default = Label("//tools:service_worker"),
            allow_single_file = True,
        ),
        "_assemble": attr.label(
            default = Label("//tools:assemble_html"),
            allow_single_file = True,
        ),
    },
    outputs = {
        "tar": "%{name}.tar",
    },
)
"""Produce a tarball of the UI ready to be served

#Args:
#  srcs: The js files to compress
#  deps: NPM modules that are needed to run uglify
#  map: The name of an optional output source map file. Not
#    required if source maps are inlined.
#  dest: The name of the compressed js file
#  opts: Options to be passed on the command line that have no
#    argument
#  string_opts: Options to be passed on the command line that have an
#    argument
"""
