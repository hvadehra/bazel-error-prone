## Run builds
bazel build //...

## Generate a patch

bazel build //java:lib --aspects=//refactor:run_ep.bzl%run_ep_aspect --output_groups=error_prone

This should produce an output like:  

```text
Aspect //refactor:run_ep.bzl%run_ep_aspect of //java:lib up-to-date:
  bazel-bin/java/lib-ep.patch
```