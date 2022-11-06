<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="rb_binary"></a>

## rb_binary

<pre>
rb_binary(<a href="#rb_binary-name">name</a>, <a href="#rb_binary-bin">bin</a>, <a href="#rb_binary-deps">deps</a>, <a href="#rb_binary-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rb_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_binary-bin"></a>bin |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="rb_binary-deps"></a>deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="rb_binary-srcs"></a>srcs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="rb_gem_build"></a>

## rb_gem_build

<pre>
rb_gem_build(<a href="#rb_gem_build-name">name</a>, <a href="#rb_gem_build-deps">deps</a>, <a href="#rb_gem_build-gemspec">gemspec</a>, <a href="#rb_gem_build-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rb_gem_build-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_gem_build-deps"></a>deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="rb_gem_build-gemspec"></a>gemspec |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="rb_gem_build-srcs"></a>srcs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="rb_gem_push"></a>

## rb_gem_push

<pre>
rb_gem_push(<a href="#rb_gem_push-name">name</a>, <a href="#rb_gem_push-src">src</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rb_gem_push-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_gem_push-src"></a>src |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="rb_library"></a>

## rb_library

<pre>
rb_library(<a href="#rb_library-name">name</a>, <a href="#rb_library-deps">deps</a>, <a href="#rb_library-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rb_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_library-deps"></a>deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="rb_library-srcs"></a>srcs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="rb_test"></a>

## rb_test

<pre>
rb_test(<a href="#rb_test-name">name</a>, <a href="#rb_test-bin">bin</a>, <a href="#rb_test-deps">deps</a>, <a href="#rb_test-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rb_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_test-bin"></a>bin |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="rb_test-deps"></a>deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="rb_test-srcs"></a>srcs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


