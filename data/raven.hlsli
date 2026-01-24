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
    uint    color;
};

struct Sprite_Inst {
    float3 pos;
    uint   color;
    float3 mat_x;
    float  uv_min_x;
    float3 mat_y;
    float  uv_min_y;
    float2 uv_size;
    uint   tex_slice;
    uint   _pad;
};

struct Mesh_Inst {
    float3 pos;
    float  _pad0;
    float3 mat_x;
    float  _pad1;
    float3 mat_y;
    float  _pad2;
    float3 mat_z;
    float  _pad3;
    uint color;
    uint vert_offs;
    uint tex_slice;
    uint param;
};

struct VS_Out {
    float4 pos : SV_Position;
    float3 world_pos: POS;
    float3 normal : NOR;
    float2 uv : TEX;
    float4 color : COL;
    uint   tex_slice : TEXSLICE;
};

float4 unpack_unorm8(uint val) {
    return float4(
        (val      ) & 0xFF,
        (val >>  8) & 0xFF,
        (val >> 16) & 0xFF,
        (val >> 24) & 0xFF
    ) * (1.0f / 255.0f);
}

float2 unpack_unorm16(uint val) {
    return float2(
        (val      ) & 0xFFFF,
        (val >> 16) & 0xFFFF
    ) * (1.0f / 65535.0f);
}