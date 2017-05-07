load("//tools/java:maven_jar.bzl", "maven_jar")
load("//tools/ui:npm.bzl", "npm_archive")

def npm_repositories():
    npm_archive(
        name = "jasmine",
        types_version = "2.8.9",
        version = "3.3.0",
    )
    npm_archive(
        name = "karma",
        types_version = "0.13.36",
        version = "3.1.1",
        deps = {
            "karma-chrome-launcher": "2.2.0",
            "karma-firefox-launcher": "1.1.0",
            "karma-sourcemap-loader": "0.3.7",
            "karma-jasmine": "1.1.0",
            "karma-coverage": "1.1.1",
            "jasmine-core": "2.5.2",
            "jasmine-spec-reporter": "4.1.1",
        },
    )
