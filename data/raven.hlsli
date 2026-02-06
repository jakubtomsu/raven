cbuffer global_constants : register(b0) {
    float rv_global_time;
    float rv_global_delta_time;
    uint  rv_global_frame;
    int2  rv_global_resolution;
    uint  rv_global_rand_seed;
    uint  rv_global_param0;
    uint  rv_global_param1;
    uint  rv_global_param2;
    uint  rv_global_param3;
}

cbuffer layer_constants : register(b1) {
    float4x4 view_proj;
    float3 cam_pos;
    int layer_index;
}

cbuffer batch_constants : register(b2) {
    uint instance_offset;
    uint vertex_offset;
}

struct Vertex {
    float3  pos;
    float   _pad;
    float2  uv;
    uint    normal;
    uint    col;
};

struct Sprite_Inst {
    float3 pos;
    uint   col;
    float3 mat_x;
    uint   uv_min;
    float3 mat_y;
    uint   uv_size;
    uint   add_col;
    uint   param;
    uint   tex_slice;
    uint   _pad0;
};

struct Mesh_Inst {
    float3 pos;
    uint col;
    float3 mat_x;
    uint add_col;
    float3 mat_y;
    uint tex_slice_vert_offs;
    float3 mat_z;
    uint param;
};

struct VS_Out {
    float4 pos : SV_Position;
    float3 world_pos : POS;
    float3 normal : NOR;
    float2 uv : TEX;
    float4 col : COL;
    float4 add_col : ADD_COL;
    uint   tex_slice : TEXSLICE;
};

float4 unpack_unorm8(uint val) {
    return float4(
        (val      ) & 0xff,
        (val >>  8) & 0xff,
        (val >> 16) & 0xff,
        (val >> 24) & 0xff
    ) * (1.0f / 255.0f);
}

float2 unpack_unorm16(uint val) {
    return float2(
        (val      ) & 0xffff,
        (val >> 16) & 0xffff
    ) * (1.0f / 65535.0f);
}


float4 unpack_signed_color_unorm8(uint val) {
    return unpack_unorm8(val) * 4.0f - 2.0f;
}

float2 unpack_uv_unorm16(uint val) {
    return unpack_unorm16(val) * 16.0f - 8.0f;
}
