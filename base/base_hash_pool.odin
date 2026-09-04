package ravn_base

import "base:intrinsics"

HASH_POOL_MAX_PROBE_DIST :: 32

Hash_Pool :: struct($N: int, $D: typeid, $H: typeid) where
    intrinsics.type_has_field(H, "index"),
    intrinsics.type_has_field(H, "gen")
{
    gen:    [N]Handle_Gen,
    hash:   [N]u64,
    data:   [N]D,
}

// Call to initialize and destroy. Does not clear generation counters and values - garbage is fine.
hash_pool_clear :: proc "contextless" (pool: ^$T/Hash_Pool($N, $D, $H)) {
    intrinsics.mem_zero(&pool.hash, size_of(pool.hash))
}

@(require_results)
hash_pool_has :: proc "contextless" (pool: $T/Hash_Pool($N, $D, $H), handle: H) -> bool {
    return handle.index > 0 && handle.index < Handle_Index(N) && handle.gen == pool.gen[handle.index]
}

@(require_results)
hash_pool_find_free :: proc(pool: $T/Hash_Pool($N, $D, $H), hash: u64) -> (handle: H, found_existing: bool, ok: bool) {
    assert(hash != 0)
    for offs in 0..<u64(HASH_POOL_MAX_PROBE_DIST) {
        slot := (hash + offs) %% u64(N)
        if slot != 0 && pool.hash[slot] == 0 || pool.hash[slot] == hash {
            return {index = Handle_Index(slot), gen = pool.gen[slot]}, pool.hash[slot] == hash, true
        }
    }
    return {}, false, false
}

@(require_results)
hash_pool_find :: proc "contextless" (pool: $T/Hash_Pool($N, $D, $H), hash: u64) -> (H, bool) {
    assert(hash != 0)
    for offs in 0..<u64(HASH_POOL_MAX_PROBE_DIST) {
        slot := (hash + offs) %% u64(N)
        if pool.hash[slot] == 0 {
            return {index = Handle_Index(slot), gen = pool.gen[index]}
        }
    }
    return {}, false
}

@(require_results)
hash_pool_insert :: proc "contextless" (pool: ^$T/Hash_Pool($N, $D, $H), hash: u64, handle: H, data: D) -> bool {
    if !hash_pool_has(pool^, handle) {
        return false
    }
    pool.hash[handle.index] = hash
    pool.data[handle.index] = data
    return true
}

@(require_results)
hash_pool_remove :: proc(pool: ^$T/Hash_Pool($N, $D, $H), handle: H) -> bool {
    if !hash_pool_has(pool^, handle) {
        return false
    }
    pool.gen[handle.index] += 1
    pool.hash[handle.index] = 0
    return true
}

@(require_results)
hash_pool_get :: proc(pool: ^$T/Hash_Pool($N, $D, $H), handle: H) -> (^D, bool) {
    if !hash_pool_has(pool^, handle) {
        return nil, false
    }
    assert(pool.hash[handle.index] != 0)
    return &pool.data[handle.index], true
}
