cbuffer batch_constants : register(b0) {
    uint instance_offset;
    uint vertex_offset;
}

cbuffer layer_constants : register(b1) {
    float4x4 view_proj;
    float3 cam_pos;
}

struct Vertex {
    float3  pos;
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
};

struct Mesh_Inst {
    float3 pos;
    float3x3 mat;
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