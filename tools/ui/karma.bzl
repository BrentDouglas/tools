load(
    "@build_bazel_rules_nodejs//internal:node.bzl",
    "expand_path_into_runfiles",
    "sources_aspect",
)
load("@io_bazel_rules_webtesting//web:web.bzl", "web_test_suite")
load(
    "//tools:util.bzl",
    "get_debug_commands",
    "is_any_jar",
    "is_tgz",
)

def _extract_module(path):
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

def _short_path_to_manifest_path(ctx, short_path):
    if short_path.startswith("../"):
        return short_path[3:]
    else:
        return ctx.workspace_name + "/" + short_path

def _karma_test_impl(ctx):
    base = ctx.bin_dir.path
    gen_base = ctx.genfiles_dir.path
    srcs = ctx.files.srcs
    html = ctx.files.html
    deps = ctx.files.deps
    base_url = ctx.attr.base_url
    browsers = ctx.attr.browsers
    port = ctx.attr.port
    debug_port = ctx.attr.debug_port
    timeout = ctx.attr.wait_timeout if ctx.attr.wait_timeout else 10000

    conf = ctx.actions.declare_file(
        "%s.conf.js" % ctx.label.name,
        sibling = ctx.outputs.executable,
    )
    shim = ctx.actions.declare_file(
        "%s.shim.js" % ctx.label.name,
        sibling = ctx.outputs.executable,
    )

    debug = ""
    log_level = "LOG_DEBUG" if browsers and browsers[0].endswith("Debug") else "LOG_INFO"
    preprocessors = "'coverage'"
    timeout = 10000
    if ctx.attr.debug == "node":
        debug = " --inspect-brk"
        log_level = "LOG_DEBUG"
        preprocessors = ""
        debug_cmds = []
    elif ctx.attr.debug == "karma":
        debug = " --inspect"
        log_level = "LOG_DEBUG"
        preprocessors = ""
        timeout = 100000

        # debug_cmds = ["( open 'http://localhost:9000/webkit/inspector/inspector.html?page=2' & )"]
        # Unless there is a way to go to this page with devtool automatically open we can't use this
        debug_cmds = ["( open 'http://localhost:%s/debug.html' & )" % debug_port]
    elif ctx.attr.debug == "rule":
        debug_cmds = get_debug_commands(ctx, "$p/%s" % conf.short_path)
    else:
        debug_cmds = []

    files = depset(srcs)
    for d in ctx.attr.deps:
        if hasattr(d, "node_sources"):
            files = depset(transitive = [files, d.node_sources])
        elif hasattr(d, "files"):
            files = depset(transitive = [files, d.files])

    templates = ",\n  ".join(["'%s/%s'" % (ctx.workspace_name, f.short_path) for f in html])
    ctx.actions.expand_template(
        output = shim,
        template = ctx.file._shim_tmpl,
        substitutions = {
            "TMPL_TEMPLATES": templates,
        },
    )

    # Finally we load the user's srcs and deps
    user_entries = ["%s/%s" % (ctx.workspace_name, f.short_path) for f in (depset(transitive = [depset([shim]), files]).to_list())]
    config_segments = len(conf.short_path.split("/"))

    ctx.actions.expand_template(
        output = conf,
        template = ctx.file._conf_tmpl,
        substitutions = {
            "TMPL_FILES": ",\n    ".join(["'%s'" % e for e in user_entries]),
            "TMPL_PATH": "/".join([".."] * config_segments),
            "TMPL_BASE_URL": "%s/%s" % (ctx.workspace_name, ctx.label.package),
            "TMPL_LOG_LEVEL": log_level,
            "TMPL_PREPROCESSORS": preprocessors,
            "TMPL_TIMEOUT": str(timeout),
            "TMPL_DEBUG_PORT": str(debug_port),
            "TMPL_PORT": str(port),
            "TMPL_TEMPLATES": templates,
            "TMPL_BROWSERS": ",".join(["'%s'" % browser for browser in browsers]) if browsers else ""
        },
    )

    karma_runfiles = [ctx.file._node, conf, shim, ctx.file.karma] + srcs + deps + html

    cmd = " \\\n  && ".join([
        "r=$PWD",
        "cd ..", #TODO why
        "export PATH",
        "p=$PWD",
        _extract_module("%s/%s" % (ctx.workspace_name, ctx.file.karma.path)),
        "export NODE_PATH=$p/node_modules",
    ] + debug_cmds + [
        "$r/%s %s $p/node_modules/karma/bin/karma start $r/%s" % (ctx.file._node.path, debug, conf.short_path),
    ])

    ctx.actions.write(
        output = ctx.outputs.executable,
        is_executable = True,
        content = cmd,
    )
    return [DefaultInfo(
        files = depset([ctx.outputs.executable]),
        runfiles = ctx.runfiles(
            files = karma_runfiles,
            transitive_files = files,
            # Propagate karma_bin and its runfiles
            collect_data = True,
            collect_default = True,
        ),
        executable = ctx.outputs.executable,
    )]

karma_test = rule(
    implementation = _karma_test_impl,
    test = True,
    executable = True,
    attrs = {
        "srcs": attr.label_list(
            doc = "JavaScript source files",
            allow_files = [".js"],
        ),
        "html": attr.label_list(
            doc = "HTML source files",
            allow_files = [".html"],
        ),
        "deps": attr.label_list(
            doc = "Other targets which produce JavaScript such as `ts_library`",
            allow_files = True,
            aspects = [sources_aspect],
        ),
        "data": attr.label_list(
            doc = "Runtime dependencies",
        ),
        "wait_timeout": attr.int(),
        "port": attr.int(mandatory = True),
        "debug_port": attr.int(mandatory = True),
        "browsers": attr.string_list(),
        "base_url": attr.string(default = "./"),
        "debug": attr.string(),
        "karma": attr.label(
            default = Label("@karma//pkg"),
            cfg = "target",
            allow_single_file = True,
        ),
        "_conf_tmpl": attr.label(
            default = Label("//tools/ui:karma-conf"),
            allow_single_file = True,
        ),
        "_shim_tmpl": attr.label(
            default = Label("//tools/ui:karma-shim"),
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
"""Runs unit tests in a browser.

When executed under `bazel test`, this uses a headless browser for speed.
This is also because `bazel test` allows multiple targets to be tested together,
and we don't want to open a Chrome window on your machine for each one. Also,
under `bazel test` the test will execute and immediately terminate.

Running under `ibazel test` gives you a "watch mode" for your tests. The rule is
optimized for this case - the test runner server will stay running and just
re-serve the up-to-date JavaScript source bundle.

To debug a single test target, run it with `bazel run` instead. This will open a
browser window on your computer. Also you can use any other browser by opening
the URL printed when the test starts up. The test will remain running until you
cancel the `bazel run` command.

Currently this rule uses Karma as the test runner, but this is an implementation
detail. We might switch to another runner like Jest in the future.
"""

# This macro exists only to modify the users rule definition a bit.
# DO NOT add composition of additional rules here.
def karma_test_macro(
        karma = Label("@karma//pkg"),
        tags = [],
        data = [],
        **kwargs):
    """ibazel wrapper for `typescript_web_test`

    This macro re-exposes the `typescript_web_test` rule with some extra tags so that
    it behaves correctly under ibazel.

    This is re-exported in `//:defs.bzl` as `typescript_web_test` so if you load the rule
    from there, you actually get this macro.

    Args:
      karma: karma binary label
      tags: standard Bazel tags, this macro adds a couple for ibazel
      data: runtime dependencies
      **kwargs: passed through to `typescript_web_test`
    """

    karma_test(
        karma = karma,
        tags = tags + [
            # Always attach this label to allow filtering, eg. envs w/ no browser
            "browser:chromium-system",
        ],
        # Our binary dependency must be in data[] for collect_data to pick it up
        # FIXME: maybe we can just ask the attr.karma for its runfiles attr
        data = data + [karma],
        **kwargs
    )

def karma_web_test_suite(
        name,
        browsers = ["@io_bazel_rules_webtesting//browsers:chromium-local"],
        karma = Label("@karma//pkg"),
        args = None,
        browser_overrides = None,
        config = None,
        flaky = None,
        local = None,
        shard_count = None,
        size = None,
        tags = [],
        test_suite_tags = None,
        timeout = None,
        visibility = None,
        web_test_data = [],
        wrapped_test_tags = [],
        debug = None,
        **remaining_keyword_args):
    """Defines a test_suite of web_test targets that wrap a typescript_web_test target.

    Args:
      name: The base name of the test.
      browsers: A sequence of labels specifying the browsers to use.
      karma: karma binary label
      args: Args for web_test targets generated by this extension.
      browser_overrides: Dictionary; optional; default is an empty dictionary. A
        dictionary mapping from browser names to browser-specific web_test
        attributes, such as shard_count, flakiness, timeout, etc. For example:
        {'//browsers:chrome-native': {'shard_count': 3, 'flaky': 1}
         '//browsers:firefox-native': {'shard_count': 1, 'timeout': 100}}.
      config: Label; optional; Configuration of web test features.
      flaky: A boolean specifying that the test is flaky. If set, the test will
        be retried up to 3 times (default: 0)
      local: boolean; optional.
      shard_count: The number of test shards to use per browser. (default: 1)
      size: A string specifying the test size. (default: 'large')
      tags: A list of test tag strings to apply to each generated web_test target.
        This macro adds a couple for ibazel.
      test_suite_tags: A list of tag strings for the generated test_suite.
      timeout: A string specifying the test timeout (default: computed from size)
      visibility: List of labels; optional.
      web_test_data: Data dependencies for the web_test.
      wrapped_test_tags: A list of test tag strings to use for the wrapped test
      **remaining_keyword_args: Arguments for the wrapped test target.
    """

    size = size or "large"

    wrapped_test_name = name + "_wrapped_test"

    # Our binary dependency must be in data[] for collect_data to pick it up
    # FIXME: maybe we can just ask the attr.karma for its runfiles attr
    web_test_data = web_test_data + [karma]

    wr_tags = wrapped_test_tags + ["manual"]

    karma_test(
        name = wrapped_test_name,
        karma = karma,
        args = args,
        flaky = flaky,
        local = local,
        shard_count = shard_count,
        size = size,
        tags = wr_tags,
        timeout = timeout,
        port = 9876,
        debug_port = 9976,
        debug = debug,
        visibility = ["//visibility:private"],
        **remaining_keyword_args
    )

    web_test_suite(
        name = name,
        launcher = ":" + wrapped_test_name,
        args = args,
        browsers = browsers,
        browser_overrides = browser_overrides,
        config = config,
        data = web_test_data,
        flaky = flaky,
        local = local,
        shard_count = shard_count,
        size = size,
        tags = tags,
        test = wrapped_test_name,
        test_suite_tags = test_suite_tags,
        timeout = timeout,
        visibility = visibility,
    )
