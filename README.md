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


<a id="rb_gem"></a>

## rb_gem

<pre>
rb_gem(<a href="#rb_gem-name">name</a>, <a href="#rb_gem-deps">deps</a>, <a href="#rb_gem-gemspec">gemspec</a>, <a href="#rb_gem-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rb_gem-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_gem-deps"></a>deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="rb_gem-gemspec"></a>gemspec |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="rb_gem-srcs"></a>srcs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


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


