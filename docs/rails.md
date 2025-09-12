<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public definition for `rails_test_factory`.

<a id="rails_test_factory.new_system_test"></a>

## rails_test_factory.new_system_test

<pre>
load("@rules_ruby//rails:rails_test_factory.bzl", "rails_test_factory")

rails_test_factory.new_system_test(<a href="#rails_test_factory.new_system_test-test_package">test_package</a>, <a href="#rails_test_factory.new_system_test-application_system_test_case">application_system_test_case</a>, <a href="#rails_test_factory.new_system_test-default_includes">default_includes</a>,
                                   <a href="#rails_test_factory.new_system_test-default_size">default_size</a>, <a href="#rails_test_factory.new_system_test-tags">tags</a>)
</pre>

Create a `rails_system_test` macro for a Rails application.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rails_test_factory.new_system_test-test_package"></a>test_package |  Optional. The name of the package that contains the test helpers. For example, if the Rails app is rooted in the `foo` directory, the test package is typically `foo/test`.   |  `None` |
| <a id="rails_test_factory.new_system_test-application_system_test_case"></a>application_system_test_case |  Optional. The label for the Rails application's `application_system_test_case.rb`.   |  `None` |
| <a id="rails_test_factory.new_system_test-default_includes"></a>default_includes |  Optional. A `list` of Ruby includes that should be part of the Ruby test invocation.   |  `None` |
| <a id="rails_test_factory.new_system_test-default_size"></a>default_size |  Optional. The default test size for the tests created with the resulting macro.   |  `"large"` |
| <a id="rails_test_factory.new_system_test-tags"></a>tags |  Optional. A `list` of tags that are added to the test declaration.   |  `["no-sandbox"]` |

**RETURNS**

A Bazel macro function that defines Rails system test targets using the
  provided attributes.


<a id="rails_test_factory.new_test"></a>

## rails_test_factory.new_test

<pre>
load("@rules_ruby//rails:rails_test_factory.bzl", "rails_test_factory")

rails_test_factory.new_test(<a href="#rails_test_factory.new_test-test_package">test_package</a>, <a href="#rails_test_factory.new_test-test_helper">test_helper</a>, <a href="#rails_test_factory.new_test-default_includes">default_includes</a>, <a href="#rails_test_factory.new_test-default_size">default_size</a>, <a href="#rails_test_factory.new_test-tags">tags</a>)
</pre>

Create a `rails_test` macro for a Rails application.

The resulting macro encapsulates the application-specific attributes for the
resulting test target.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rails_test_factory.new_test-test_package"></a>test_package |  Optional. The name of the package that contains the test helpers. For example, if the Rails app is rooted in the `foo` directory, the test package is typically `foo/test`.   |  `None` |
| <a id="rails_test_factory.new_test-test_helper"></a>test_helper |  The label for the Rails application's `test_helper.rb`.   |  `None` |
| <a id="rails_test_factory.new_test-default_includes"></a>default_includes |  Optional. A `list` of Ruby includes that should be part of the Ruby test invocation.   |  `None` |
| <a id="rails_test_factory.new_test-default_size"></a>default_size |  Optional. The default test size for the tests created with the resulting macro.   |  `"small"` |
| <a id="rails_test_factory.new_test-tags"></a>tags |  Optional. A `list` of tags that are added to the test declaration.   |  `[]` |

**RETURNS**

A Bazel macro function that defines Rails test targets using the
  provided attributes.


