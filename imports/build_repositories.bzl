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
        version = "2.0.2",
        types = False,
        deps = {
            "csso": "3.5.1",
        },
    )
    npm_archive(
        name = "typescript",
        version = "3.4.3",
        types = False,
    )
    npm_archive(
        name = "tslint",
        version = "5.15.0",
        types = False,
    )
    npm_archive(
        name = "html-minifier",
        version = "4.0.0",
        types = False,
    )
    npm_archive(
        name = "webfont",
        types = False,
        version = "8.2.1",
    )
    npm_archive(
        name = "uglify-js",
        types = False,
        version = "3.4.5",
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
        version = "0.34.3",
        types = False,
    )
    npm_archive(
        name = "node-sass",
        version = "4.11.0",
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
        version = "1.10.1",
        types = False,
        deps = {
            "rollup-plugin-babel": "4.3.2",
            "rollup-plugin-commonjs": "9.3.4",
            "rollup-plugin-node-resolve": "4.2.3",
            "rollup-plugin-replace": "2.2.0",
            "rollup-plugin-sourcemaps": "0.4.2",
            "rollup-plugin-multi-entry": "2.1.0",
            "@babel/core": "7.4.3",
        },
    )
    npm_archive(
        name = "babel-cli",
        package = "@babel/cli",
        version = "7.4.3",
        types = False,
        deps = {
            "@babel/core": "7.4.3",
            "@babel/preset-env": "7.4.4",
        },
    )
    npm_archive(
        name = "webpack",
        version = "4.30.0",
        types = False,
    )
    npm_archive(
        name = "source-map-loader",
        version = "0.2.4",
        types = False,
    )
    npm_archive(
        name = "jest",
        version = "24.7.1",
        types_package = "@jest/types",
        types_version = "24.7.0",
    )
    npm_archive(
        name = "google-closure-compiler",
        version = "20190415.0.0",
        types = False,
    )
