"""Module for defining Rails test macros."""

load("@rules_ruby//ruby:defs.bzl", "rb_test")

def _new_assert(value, msg):
    """Create an assert function for the specified value.

    The assert function that is returned will return the value if it is not
    `None`. Otherwise, it will fail with the provided message.

    Args:
        value: The value to check for not `None`.
        msg: The failure message as a `string`.


    Returns:
        An assert function for the value.
    """

    def _assert():
        if value != None:
            return value
        fail(msg)

    return _assert

def _new_test(
        test_package = None,
        test_helper = None,
        default_includes = None,
        default_size = "small",
        tags = []):
    """Create a `rails_test` macro for a Rails application.

    The resulting macro encapsulates the application-specific attributes for the
    resulting test target.

    Args:
        test_package: Optional. The name of the package that contains the test
            helpers. For example, if the Rails app is rooted in the `foo`
            directory, the test package is typically `foo/test`.
        test_helper: The label for the Rails application's `test_helper.rb`.
        default_includes: Optional. A `list` of Ruby includes that should be
            part of the Ruby test invocation.
        default_size: Optional. The default test size for the tests created with
            the resulting macro.
        tags: Optional. A `list` of tags that are added to the test declaration.

    Returns:
        A Bazel macro function that defines Rails test targets using the
        provided attributes.
    """

    _assert_test_package = _new_assert(
        test_package,
        "A value for `test_package` was not provided.",
    )

    if test_helper == None:
        test_helper = "//{pkg}:test_helper".format(pkg = _assert_test_package())
    if default_includes == None:
        default_includes = [_assert_test_package()]

    def _rails_test(name, src, **kwargs):
        """Defines a Rails test target.

        Args:
            name: The name of the test target as a `string`.
            src: The Ruby test filename.
            **kwargs: The attributes that should be passed to the underlying
                `rb_test` declaration.
        """
        if default_size:
            kwargs["size"] = kwargs.pop("size", default_size)

        if tags:
            current_tags = kwargs.pop("tags", [])
            for tag in tags:
                if tag not in current_tags:
                    current_tags.append(tag)
            kwargs["tags"] = current_tags

        kwargs["deps"] = [test_helper] + kwargs.pop("deps", [])

        includes = kwargs.pop("includes", default_includes)
        include_args = ["-I{}".format(incl) for incl in includes]

        rb_test(
            name = name,
            srcs = [src],
            args = include_args + ["$(location {})".format(src)],
            **kwargs
        )

    return _rails_test

def _new_system_test(
        test_package = None,
        application_system_test_case = None,
        default_includes = None,
        default_size = "large",
        tags = ["no-sandbox"]):
    """Create a `rails_system_test` macro for a Rails application.

    Args:
        test_package: Optional. The name of the package that contains the test
            helpers. For example, if the Rails app is rooted in the `foo`
            directory, the test package is typically `foo/test`.
        application_system_test_case: Optional. The label for the Rails
            application's `application_system_test_case.rb`.
        default_includes: Optional. A `list` of Ruby includes that should be
            part of the Ruby test invocation.
        default_size: Optional. The default test size for the tests created with
            the resulting macro.
        tags: Optional. A `list` of tags that are added to the test declaration.

    Returns:
        A Bazel macro function that defines Rails system test targets using the
        provided attributes.
    """

    _assert_test_package = _new_assert(
        test_package,
        "A value for `test_package` was not provided.",
    )
    if application_system_test_case == None:
        application_system_test_case = """\
//{pkg}:application_system_test_case\
""".format(pkg = _assert_test_package())

    return _new_test(
        test_package = test_package,
        test_helper = application_system_test_case,
        default_includes = default_includes,
        default_size = default_size,
        tags = tags,
    )

rails_test_factory = struct(
    new_test = _new_test,
    new_system_test = _new_system_test,
)
