load("//tools/java:maven_jar.bzl", "maven_jar")
load("//tools/ui:npm.bzl", "npm_archive")

def build_repositories(
        com_google_javascript_closure_compiler_version = "v20180101",
        com_googlecode_htmlcompressor_htmlcompressor_version = "1.5.2",
        com_yahoo_platform_yui_yuicompressor_version = "2.4.8"):
    maven_jar(
        name = "com_google_javascript_closure_compiler",
        artifact = "com.google.javascript:closure-compiler:" + com_google_javascript_closure_compiler_version,
    )
    maven_jar(
        name = "com_googlecode_htmlcompressor_htmlcompressor",
        artifact = "com.googlecode.htmlcompressor:htmlcompressor:" + com_googlecode_htmlcompressor_htmlcompressor_version,
    )
    maven_jar(
        name = "com_yahoo_platform_yui_yuicompressor",
        artifact = "com.yahoo.platform.yui:yuicompressor:" + com_yahoo_platform_yui_yuicompressor_version,
    )

    npm_archive(
        name = "csso-cli",
        version = "1.1.0",
        types = False,
        deps = {
            "csso": "3.5.1",
        },
    )
    npm_archive(
        name = "typescript",
        version = "3.1.3",
        types = False,
    )
    npm_archive(
        name = "tslint",
        version = "5.11.0",
        types = False,
    )
    npm_archive(
        name = "html-minifier",
        version = "3.5.21",
        types = False,
    )
    npm_archive(
        name = "webfont",
        types = False,
        version = "8.1.4",
    )

    #  npm_archive(
    #      name = "grpc-web-client",
    #      version = "0.3.1",
    #      types = False,
    #  )
    #  npm_archive(
    #      name = "ts-protoc-gen",
    #      version = "0.4.0",
    #      types = False,
    #  )
    npm_archive(
        name = "tsickle",
        version = "0.29.0",
        types = False,
    )
    npm_archive(
        name = "node-sass",
        version = "4.9.4",
        types = False,
        rebuild = True,
    )
    npm_archive(
        name = "source-map",
        version = "0.7.3",
        types = False,
    )
    npm_archive(
        name = "rollup",
        version = "0.60.7",
        types = False,
        deps = {
            "rollup-plugin-commonjs": "9.1.3",
            "rollup-plugin-node-resolve": "3.3.0",
            "rollup-plugin-replace": "2.0.0",
            "rollup-plugin-sourcemaps": "0.4.2",
            "rollup-plugin-multi-entry": "2.0.2",
        },
    )
    npm_archive(
        name = "webpack",
        version = "4.12.0",
        types = False,
    )
    npm_archive(
        name = "source-map-loader",
        version = "0.2.3",
        types = False,
    )
    npm_archive(
        name = "jest",
        version = "23.1.0",
        types_version = "23.0.2",
    )
