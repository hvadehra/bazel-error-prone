load("@rules_java//java:defs.bzl", "JavaInfo")

# https://errorprone.info/docs/installation#command-line
_JAVAC_OPTS = [
    "-J--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
    "-J--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED",
    "-J--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED",
    "-J--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED",
    "-J--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED",
    "-J--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED",
    "-J--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED",
    "-J--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED",
    "-J--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED",
    "-J--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED",
    "-XDcompilePolicy=simple",
]

def _impl(target, ctx):
    javac_actions = [a for a in target.actions if a.mnemonic == "Javac"]

    if not JavaInfo in target or not javac_actions:
        return []

    java_info = target[JavaInfo]
    javac_a = javac_actions[0]  # should only be one, else we could loop over all
    srcjar_action = [a for a in target.actions if a.mnemonic == "JavaSourceJar"][0]
    cp = ":".join([f.path for f in java_info.compilation_info.compilation_classpath.to_list()])

    out = ctx.actions.declare_file(ctx.label.name + "-ep.patch")
    classfile_dir = ctx.actions.declare_directory("classes")
    ctx.actions.run_shell(
        command = """
        set -e
        javac \
         {JAVAC_OPTS} \
         {CLASSPATH} \
         -d {CLASS_OUTPUT_DIR} \
         -processorpath {ERROR_PRONE_FILES} \
         '-Xplugin:ErrorProne -XepPatchChecks:{ERROR_PRONE_PATCH_CHECKS} -XepPatchLocation:/tmp' \
         {JAVA_SOURCE_FILES}
         mv /tmp/error-prone.patch {PATCH_OUTPUT} || touch {PATCH_OUTPUT}
         """.format(
            JAVAC_OPTS = " ".join(_JAVAC_OPTS),
            CLASSPATH = "-cp " + cp if cp else "",
            CLASS_OUTPUT_DIR = classfile_dir.path,
            ERROR_PRONE_FILES = ":".join([f.path for f in ctx.files._error_prone]),
            ERROR_PRONE_PATCH_CHECKS = ",".join(["MissingOverride"]),
            JAVA_SOURCE_FILES = " ".join([f.short_path for f in srcjar_action.inputs.to_list() if f.extension == "java"]),
            PATCH_OUTPUT = out.path,
        ),
        inputs = depset(
            ctx.files._error_prone,
            transitive = [javac_a.inputs, srcjar_action.inputs],
        ),
        outputs = [out, classfile_dir],
    )

    return [
        OutputGroupInfo(
            error_prone = depset([out]),
        ),
    ]

run_ep_aspect = aspect(
    implementation = _impl,
    attrs = {
        "_error_prone": attr.label(default = "//refactor:error_prone_files"),
    },
)
