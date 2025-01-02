#include "native_ext.h"

VALUE rb_mNativeExt;

RUBY_FUNC_EXPORTED void
Init_native_ext(void)
{
  rb_mNativeExt = rb_define_module("NativeExt");
}
