### Important

  - Setup CI
  - Test with other Ruby versions.
  - Stabilize the test suite.

### Explore

- C extension for a allocation free `ObjectSpace.dump_all` https://bugs.ruby-lang.org/issues/17045.
- Performance optimization.
  - Use `fast_jsonparser`? Only if available?
  - Implement a custom parser based on simdjson?
- Detect object growth?
