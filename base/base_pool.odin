package ravn_base

import "base:intrinsics"

Pool :: struct($N: int, $D: typeid, $H: typeid) where
    intrinsics.type_has_field(H, "index"),
    intrinsics.type_has_field(H, "gen")
{
    used:   Bit_Pool(N),
    gen:    [N]Handle_Gen,
    data:   [N]D,
}

// Call to initialize and destroy. Does not clear generation counters and values - garbage is fine.
pool_clear :: proc "contextless" (pool: ^$T/Pool($N, $D, $H)) {
    bit_pool_clear(&pool.used)
    bit_pool_set_1(&pool.used, 0)
}

@(require_results)
pool_has :: proc "contextless" (pool: $T/Pool($N, $D, $H), handle: H) -> bool {
    return handle.index > 0 && handle.index < Handle_Index(N) && handle.gen == pool.gen[handle.index]
}

@(require_results)
pool_find_free :: proc "contextless" (pool: $T/Pool($N, $D, $H)) -> (handle: H, ok: bool) {
    index := bit_pool_find_0(pool.used) or_return
    return {index = Handle_Index(index), gen = pool.gen[index]}, true
}

@(require_results)
pool_insert :: proc "contextless" (pool: ^$T/Pool($N, $D, $H), handle: H, data: D) -> bool {
    if !pool_has(pool^, handle) || bit_pool_is_1(pool.used, handle.index) {
        return false
    }
    bit_pool_set_1(&pool.used, handle.index)
    pool.data[handle.index] = data
    return true
}

@(require_results)
pool_remove :: proc(pool: ^$T/Pool($N, $D, $H), handle: H) -> bool {
    if !pool_has(pool^, handle) {
        return false
    }
    assert(bit_pool_is_1(pool.used, handle.index))
    bit_pool_set_0(&pool.used, handle.index)
    pool.gen[handle.index] += 1
    return true
}

@(require_results)
pool_get :: proc(pool: ^$T/Pool($N, $D, $H), handle: H) -> (^D, bool) {
    if !pool_has(pool^, handle) {
        return nil, false
    }
    assert(bit_pool_is_1(pool.used, handle.index))
    return &pool.data[handle.index], true
}
