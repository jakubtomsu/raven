#+vet explicit-allocators shadowing style
package raven_gpu

import "base:intrinsics"
import "base:runtime"
import "core:log"

_ :: log

ptr_bytes :: proc(ptr: ^$T, len := 1) -> []byte {
    return transmute([]byte)runtime.Raw_Slice{ptr, len * size_of(T)}
}

slice_bytes :: proc(s: []$T) -> []byte where T != byte {
    return ([^]byte)(raw_data(s))[:len(s) * size_of(T)]
}

// Cache bucket for lightweight resources.
// Linear SOA search.
Bucket :: struct($Num: int, $Key: typeid, $Val: typeid) {
    len:    i32,
    keys:   [Num]Key,
    vals:   [Num]Val,
}

bucket_find_or_create :: proc(
    bucket:         ^$T/Bucket($N, $K, $V),
    key:            K,
    create_proc:    proc(K) -> V,
) -> (result: V) {
    for i in 0..<bucket.len {
        if key == bucket.keys[i] {
            return bucket.vals[i]
        }
    }

    index := bucket.len
    if index >= len(bucket.keys) {
        log.errorf("{} Cache Bucket is full", type_info_of(V))
        return {}
    }

    // log.infof("{} Cache Miss", type_info_of(V))

    result = create_proc(key)

    bucket.keys[index] = key
    bucket.vals = result
    bucket.len += 1

    return result
}



Bit_Pool :: struct($N: int) where N % 64 == 0, N > 0 {
    l0: [(N + 4095) / 4096]u64,
    l1: [N / 64]u64,
}

@(require_results)
bit_pool_find_0 :: proc "contextless" (bp: Bit_Pool($N)) -> (index: int, ok: bool) {
    l1_index := -1
    when N > 64 {
        for used, i in bp.l0 {
            l0_slot := int(intrinsics.count_trailing_zeros(~used))
            if l0_slot != 64 {
                l1_index = 64 * i + l0_slot
                break
            }
        }
    } else {
        l1_index = 0
    }

    if l1_index == -1 || l1_index >= (N / 64) {
        return -1, false
    }

    l1_slot := int(intrinsics.count_trailing_zeros(~bp.l1[l1_index]))
    if l1_slot != 64 {
        return l1_index * 64 + l1_slot, true
    }

    return -1, false
}

bit_pool_set_1 :: proc "contextless" (bp: ^Bit_Pool($N), #any_int index: u64) {
    l1_index := index / 64
    l1_slot := index % 64

    l0_index := l1_index / 64
    l0_slot := l1_index % 64

    bucket := bp.l1[l1_index]
    bucket |= 1 << l1_slot

    if bucket == 0xffff_ffff_ffff_ffff { // if full
        bp.l0[l0_index] |= 1 << l0_slot
    }

    bp.l1[l1_index] = bucket
}

bit_pool_set_0 :: proc "contextless" (bp: ^Bit_Pool($N), #any_int index: u64) {
    l1_index := index / 64
    l1_slot := index % 64

    l0_index := index / 4096
    l0_slot := index % 4096

    // Always clear L0, it must be non-empty after deleting from L1
    bp.l0[l0_index] &~= 1 << l0_slot
    bp.l1[l1_index] &~= 1 << l1_slot
}

@(require_results)
bit_pool_check_1 :: proc "contextless" (bp: Bit_Pool($N), #any_int index: u64) -> bool {
    l1_index := index / 64
    l1_slot := index % 64
    return (bp.l1[l1_index] & (1 << l1_slot)) != 0
}



// VERTEX BUFFERS
// this is currently unused. fuck vertex buffers actually.

/*
Vertex_Field :: struct {
    type:       Vertex_Type,
    vector_len: u8,
    normalized: bool,
    offset:     u16, // in bytes
}

Vertex_Type :: enum u8 {
    F32,
    F16,
    U32,
    U16,
    U8,
    I32,
    I16,
    I8,
}

vertex_fields_from_struct :: proc(
    type_info: ^runtime.Type_Info,
    allocator := context.temp_allocator,
    loc := #caller_location,
) -> (result: []Vertex_Field, ok: bool) {
    ti := runtime.type_info_base(type_info)
    str, str_ok := ti.variant.(runtime.Type_Info_Struct)
    if !str_ok {
        assert(false, "Must be a struct")
        return {}, false
    }

    buf := make_dynamic_array_len([dynamic]Vertex_Field, str.field_count, allocator)

    for i in 0..<str.field_count {
        log.info(str.names[i], str.types[i])

        field := vertex_field_from_type_info(str.types[i]) or_return
        assert(field.vector_len >= 1)

        field.offset = u16(str.offsets[i])

        tag_val, tag_ok := reflect.struct_tag_lookup(reflect.Struct_Tag(str.tags[i]), "gpu")
        if tag_ok {
            parts := strings.split(tag_val, ",", context.temp_allocator)
            for part in parts {
                switch part {
                case "normalized": field.normalized = true
                }
            }
        }

        buf[i] = field
    }

    return buf[:], true
}

vertex_field_from_type_info :: proc(
    type_info: ^runtime.Type_Info,
    loc := #caller_location,
) -> (result: Vertex_Field, ok: bool) {
    ti := runtime.type_info_core(type_info)
    log.info(ti)

    #partial switch v in ti.variant {
    case runtime.Type_Info_Integer:
        result.vector_len = 1
        switch ti.size {
        case 1: result.type = v.signed ? .I8  : .U8
        case 2: result.type = v.signed ? .I16 : .U16
        case 4: result.type = v.signed ? .I32 : .U32
        case:
            return {}, false
        }

        return result, true

    case runtime.Type_Info_Float:
        result.vector_len = 1
        switch ti.size {
        case 2: result.type = .F16
        case 4: result.type = .F32
        }

        return result, true

    case runtime.Type_Info_Array:
        if v.count <= 0 || v.count > 4 {
            log.error("Invalid array size, must be 1, 2, 3 or 4")
            return {}, false
        }

        result = vertex_field_from_type_info(v.elem, loc = loc) or_return

        result.vector_len = u8(v.count)

        return result, true

    case runtime.Type_Info_Quaternion:
        result.vector_len = 4
        switch ti.size {
        case 64: result.type = .F16
        case 128: result.type = .F32
        case:
            log.error("Invalid quternion size")
            return {}, false
        }

        return result, true

    case:

        name := ""
        named, named_ok := type_info.variant.(runtime.Type_Info_Named)
        if named_ok {
            name = named.name
        }

        log.error("Field '{}' ({}) is not a valid vertex field, must be internally an integer or an float")
        return {}, false
    }

    return {}, false
}
*/