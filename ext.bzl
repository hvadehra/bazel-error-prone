load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

def _impl(mctx):
    [
        http_jar(name = name, url = url)
        for name, url in [
            (
                "ep_with_deps",
                "https://repo1.maven.org/maven2/com/google/errorprone/error_prone_core/2.35.1/error_prone_core-2.35.1-with-dependencies.jar",
            ),
        ]
    ]

external = module_extension(_impl)
