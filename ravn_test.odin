#+test
#+vet shadowing unused
package ravn

import "core:math/linalg"
import "core:log"
import "core:testing"

@(test)
_asset_name_from_path_test :: proc(t: ^testing.T) {
    testing.expect(t, asset_name_from_path("bar.txt") == "bar")
    testing.expect(t, asset_name_from_path("foo/bar.txt") == "bar")
    testing.expect(t, asset_name_from_path("foo\\bar.txt") == "bar")
    testing.expect(t, asset_name_from_path("foo/foo2/bar.txt.bin") == "bar.txt")
}

@(test)
_file_name_from_path_test :: proc(t: ^testing.T) {
    testing.expect(t, file_name_from_path("bar.txt") == "bar.txt")
    testing.expect(t, file_name_from_path("foo/bar.txt") == "bar.txt")
    testing.expect(t, file_name_from_path("foo\\bar.txt") == "bar.txt")
    testing.expect(t, file_name_from_path("foo/foo2/bar.txt.bin") == "bar.txt.bin")
}

@(test)
_normalize_path_test :: proc(t: ^testing.T) {
    testing.expect(t, normalize_path("foo") == "foo")
    testing.expect(t, normalize_path("Foo") == "foo")
    testing.expect(t, normalize_path("Hello\\World") == "hello/world")
    testing.expect(t, normalize_path("_123_!@+你好!") == "_123_!@+你好!")
}

@(test)
_cp437_rune_char_table :: proc(t: ^testing.T) {
    for ch in 0..<max(u8) {
        testing.expectf(t, ch == rune_to_char(char_to_rune(ch)), "%v : %v", ch, char_to_rune(ch))
    }
}

@(test)
_uv_packing :: proc(t: ^testing.T) {
    for x in -8..=8 {
        for y in -8..=8 {
            p := [2]f32{f32(x), f32(y)}
            packed := pack_uv_unorm16(p)
            unpacked := unpack_uv_unorm16(packed)
            if !testing.expect(t, linalg.distance(p, unpacked) < 0.001) {
                log.info(p, packed, unpacked)
            }
        }
    }
}


@(test)
_signed_color_packing :: proc(t: ^testing.T) {
    for x in -2..=2 {
        for y in -2..=2 {
            for z in -2..=2 {
                for w in -2..=2 {
                    p := [4]f32{f32(x), f32(y), f32(z), f32(w)}
                    packed := pack_signed_color_unorm8(p)
                    unpacked := unpack_signed_color_unorm8(packed)
                    if !testing.expect(t, linalg.distance(p, unpacked) < 0.05) {
                        log.info(p, packed, unpacked)
                    }
                }
            }
        }
    }
}
