#+test
package raven

import "core:testing"

@(test)
_strip_path_name_test :: proc(t: ^testing.T) {
    testing.expect(t, strip_path_name("bar.txt") == "bar")
    testing.expect(t, strip_path_name("foo/bar.txt") == "bar")
    testing.expect(t, strip_path_name("foo\\bar.txt") == "bar")
    testing.expect(t, strip_path_name("foo/foo2/bar.txt.bin") == "bar")
}