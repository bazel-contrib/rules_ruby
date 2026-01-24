<!-- Generated with Stardoc: http://skydoc.bazel.build -->

User-facing public API for registering Ruby gRPC protoc plugin toolchains.

<a id="rb_grpc_protoc_plugin_toolchain"></a>

## rb_grpc_protoc_plugin_toolchain

<pre>
load("@rules_ruby//ruby:proto.bzl", "rb_grpc_protoc_plugin_toolchain")

rb_grpc_protoc_plugin_toolchain(<a href="#rb_grpc_protoc_plugin_toolchain-name">name</a>, <a href="#rb_grpc_protoc_plugin_toolchain-grpc_plugin">grpc_plugin</a>)
</pre>

Declare a toolchain for the Ruby gRPC protoc plugin.

NB: the toolchain produced by this macro is actually named [name]_toolchain, so THAT is what you must register.
Even better, make a dedicated 'toolchains' directory and put all your toolchains in there, then register them all with 'register_toolchains("//path/to/toolchains:all")'.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_grpc_protoc_plugin_toolchain-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="rb_grpc_protoc_plugin_toolchain-grpc_plugin"></a>grpc_plugin |  <p align="center"> - </p>   |  none |


