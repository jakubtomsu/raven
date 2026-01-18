struct Batch_Constants {
    instance_offset : u32,
    vertex_offset   : u32,
};

@group(0) @binding(8)
var<uniform> batch_constants : Batch_Constants;

struct Layer_Constants {
    view_proj : mat4x4<f32>,
    cam_pos   : vec3<f32>,
};

@group(0) @binding(9)
var<uniform> layer_constants : Layer_Constants;

struct Vertex {
    pos    : vec3<f32>,
    uv     : vec2<f32>,
    normal : u32,
    color  : u32,
};

struct Sprite_Inst {
    pos       : vec3<f32>,
    color     : u32,
    mat_x     : vec3<f32>,
    uv_min_x  : f32,
    mat_y     : vec3<f32>,
    uv_min_y  : f32,
    uv_size   : vec2<f32>,
    tex_slice : u32,
};

struct Mesh_Inst {
    pos       : vec3<f32>,
    mat       : mat3x3<f32>,
    color     : u32,
    vert_offs : u32,
    tex_slice : u32,
    param     : u32,
};

struct VS_Out {
    @builtin(position) pos : vec4<f32>,
    @location(0) world_pos : vec3<f32>,
    @location(1) normal    : vec3<f32>,
    @location(2) uv        : vec2<f32>,
    @location(3) color     : vec4<f32>,
    @location(4) tex_slice : u32,
};

fn unpack_unorm8(val : u32) -> vec4<f32> {
    return vec4<f32>(
        f32((val      ) & 0xFFu),
        f32((val >>  8) & 0xFFu),
        f32((val >> 16) & 0xFFu),
        f32((val >> 24) & 0xFFu),
    ) * (1.0 / 255.0);
}

fn unpack_unorm16(val : u32) -> vec2<f32> {
    return vec2<f32>(
        f32((val      ) & 0xFFFFu),
        f32((val >> 16) & 0xFFFFu),
    ) * (1.0 / 65535.0);
}