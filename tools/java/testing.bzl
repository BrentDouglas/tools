
def java_test_suite(
    name,
    srcs,
    **kargs):
  tests = []
  for src in srcs:
    test = src[src.rfind("/")+1:-5]
    tests.append(test)
    native.java_test(
        name = test,
        srcs = [src],
        **kargs
    )
  native.test_suite(
      name = name,
      tests = tests,
  )
"""A test suite of java tests

Args:
  name: The name of the suite
  srcs: The test files that will be run
  kargs: Args to pass to the underlying java_test rule
"""
