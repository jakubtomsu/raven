package raven_base

import "base:intrinsics"

// 2-level bitset with accelerated 0 search.
Bit_Pool :: struct($N: int) where N % 64 == 0 {
    l0: [(N + 4095) / 4096]u64,
    l1: [N / 64]u64,
}

@(require_results)
bit_pool_alloc :: proc "contextless" (bp: ^Bit_Pool($N)) -> (result: int, ok: bool) {
    result = bit_pool_find_0(bp^) or_return
    bit_pool_set_1(bp, index)
    return result, true
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
    assert_contextless(index >= 0 && index < u64(N))

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
    assert_contextless(index >= 0 && index < u64(N))

    l1_index := index / 64
    l1_slot := index % 64

    l0_index := l1_index / 64
    l0_slot := l1_index % 64

    // Always clear L0, it must be non-empty after deleting from L1
    bp.l0[l0_index] &= ~(1 << l0_slot)
    bp.l1[l1_index] &= ~(1 << l1_slot)
}

// bit_pool_get
@(require_results)
bit_pool_check_1 :: proc "contextless" (bp: Bit_Pool($N), #any_int index: u64) -> bool {
    assert_contextless(index >= 0 && index < u64(N))

    l1_index := index / 64
    l1_slot := index % 64
    return (bp.l1[l1_index] & (1 << l1_slot)) != 0
}
