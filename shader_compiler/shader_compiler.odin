#+vet explicit-allocators shadowing style
package raven_shader_compiler

import "../base"

import "base:runtime"


Target :: enum u8 {
    Invalid = 0,
    D3D11,
    WGPU,
}

Stage :: enum u8 {
    Invalid = 0,
    Vertex,
    Pixel,
    Compute,
}

Options :: struct {
    target:         Target,
    stage:          Stage,
    defines:        [][2]string,
    release:        bool,

    include_proc:   Include_Proc,
    user:           rawptr,
}

Include_Proc :: #type proc (path: string, user: rawptr) -> (string, bool)

compile :: proc(
    name:           string,
    source:         string,
    opts:           Options,
) -> (result: []byte, ok: bool) {
    switch opts.target {
    case .Invalid:
        assert(false)

    case .D3D11:
        when ODIN_OS == .Windows {
            result, ok = _compile_dxil(name, source, opts)
        } else {
            base.log_err("D3D11 shader compilation is not supported on non-windows platforms")
            assert(false)
        }

    case .WGPU:
        // TODO: Call slang/naga/dawn here...
        base.log_err("WGSL transpilation is not supported yet.")
        // HACK: for now passthrough, assume WGPU input
        return transmute([]byte)source, true
    }

    return result, ok
}

clone_to_cstring :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (res: cstring, err: runtime.Allocator_Error) #optional_allocator_error {
    c := make([]byte, len(s)+1, allocator, loc) or_return
    copy(c, s)
    c[len(s)] = 0
    return cstring(&c[0]), nil
}
