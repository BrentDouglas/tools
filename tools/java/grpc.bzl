def _path_ignoring_repository(f):
    if (len(f.owner.workspace_root) == 0):
        return f.short_path
    return f.path[f.path.find(f.owner.workspace_root) + len(f.owner.workspace_root) + 1:]

def _gensource_impl(ctx):
    if len(ctx.attr.srcs) > 1:
        fail("Only one src value supported", "srcs")
    for s in ctx.attr.srcs:
        if s.label.package != ctx.label.package:
            print(("in srcs attribute of {0}: Proto source with label {1} should be in " +
                   "same package as consuming rule").format(ctx.label, s.label))

    # Use .jar since .srcjar makes protoc think output will be a directory
    srcdotjar = ctx.actions.declare_file(ctx.label.name + "_src.jar")

    srcs = [f for dep in ctx.attr.srcs for f in dep.proto.direct_sources]
    includes = [f for dep in ctx.attr.srcs for f in dep.proto.transitive_imports.to_list()]

    flavor = ctx.attr.flavor
    if flavor == "normal":
        flavor = ""
    java_plugin = ctx.actions.declare_file("protoc-gen-grpc-java.bin")
    ctx.actions.run_shell(
        command = "cp $1 $2 && chmod +x $2",
        tools = [ctx.executable.java_plugin],
        outputs = [java_plugin],
        arguments = [ctx.executable.java_plugin.path, java_plugin.path],
    )
    ctx.actions.run(
        inputs = srcs + includes,
        outputs = [srcdotjar],
        executable = ctx.executable._protoc,
        tools = [java_plugin],
        arguments = [
                        "--plugin=protoc-gen-grpc-java=" + java_plugin.path,
                        "--grpc-java_out={0},enable_deprecated={1}:{2}".format(flavor, str(ctx.attr.enable_deprecated).lower(), srcdotjar.path),
                    ] +
                    ["-I{0}={1}".format(_path_ignoring_repository(include), include.path) for include in includes] +
                    [_path_ignoring_repository(src) for src in srcs],
    )
    ctx.actions.run_shell(
        command = "cp $1 $2",
        inputs = [srcdotjar],
        outputs = [ctx.outputs.srcjar],
        arguments = [srcdotjar.path, ctx.outputs.srcjar.path],
    )

_gensource = rule(
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_empty = False,
            providers = ["proto"],
        ),
        "flavor": attr.string(
            values = [
                "normal",
                "lite",  # Not currently supported
            ],
            default = "normal",
        ),
        "enable_deprecated": attr.bool(
            default = False,
        ),
        "_protoc": attr.label(
            default = Label("@com_google_protobuf//:protoc"),
            executable = True,
            cfg = "host",
        ),
        "java_plugin": attr.label(
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {
        "srcjar": "%{name}.srcjar",
    },
    implementation = _gensource_impl,
)

def java_grpc_library(
        name,
        srcs,
        deps,
        flavor = None,
        enable_deprecated = None,
        visibility = None,
        **kwargs):
    """Generates and compiles gRPC Java sources for services defined in a proto
    file. This rule is compatible with java_proto_library and java_lite_proto_library.
    Do note that this rule only scans through the proto file for RPC services. It
    does not generate Java classes for proto messages. You will need a separate
    java_proto_library or java_lite_proto_library rule.
    Args:
      name: (str) A unique name for this rule. Required.
      srcs: (list) a single proto_library target that contains the schema of the
          service. Required.
      deps: (list) a single java_proto_library target for the proto_library in
          srcs.  Required.
      flavor: (str) "normal" (default) for normal proto runtime. "lite"
          for the lite runtime.
      visibility: (list) the visibility list
      **kwargs: Passed through to generated targets
    """
    if flavor == None:
        flavor = "normal"

    if len(deps) > 1:
        print("Multiple values in 'deps' is deprecated in " + name)

    gensource_name = name + "__do_not_reference__srcjar"
    _gensource(
        name = gensource_name,
        srcs = srcs,
        flavor = flavor,
        enable_deprecated = enable_deprecated,
        java_plugin = select({
            "//conditions:darwin": Label("@grpc_m2//io_grpc_protoc_gen_grpc_java_osx//exe"),
            "//conditions:windows": Label("@grpc_m2//io_grpc_protoc_gen_grpc_java_windows//exe"),
            "//conditions:default": Label("@grpc_m2//io_grpc_protoc_gen_grpc_java_linux//exe"),
        }),
        visibility = ["//visibility:private"],
        **kwargs
    )

    added_deps = [
        "@grpc_m2//:io_grpc_grpc_core",
        "@grpc_m2//:io_grpc_grpc_stub",
        "@grpc_m2//:io_grpc_grpc_protobuf",
        "@grpc_m2//:com_google_guava_guava",
    ]
    if flavor == "normal":
        added_deps += ["@com_google_protobuf//:protobuf_java"]
    elif flavor == "lite":
        # TODO: This is currently blocked on https://github.com/google/protobuf/issues/2762
        added_deps += ["@com_google_protobuf_java_lite//:protobuf_java_lite"]
    else:
        fail("Unknown flavor type", "flavor")

    native.java_library(
        name = name,
        srcs = [gensource_name],
        visibility = visibility,
        deps = [
            "@grpc_m2//:com_google_code_findbugs_jsr305",
        ] + deps + added_deps,
        **kwargs
    )
