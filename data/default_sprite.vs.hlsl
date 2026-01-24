StructuredBuffer<Sprite_Inst> instances : register(t0);

VS_Out vs_main(uint vid : SV_VertexID, uint inst_id : SV_InstanceID) {
    Sprite_Inst inst = instances[inst_id + instance_offset];
    
    float2 local_uv = float2(float(vid & 1), float(vid / 2));
    
    float2 local_pos = local_uv * 2.0 - 1.0;
    
    VS_Out o;
    float3 world_pos = inst.pos  + inst.mat_x * local_pos.x + inst.mat_y * local_pos.y;
    o.pos = mul(view_proj, float4(world_pos, 1.0f));
    o.world_pos = world_pos;
    o.normal = cross(inst.mat_x, inst.mat_y);
    o.uv = float2(inst.uv_min_x, inst.uv_min_y) + inst.uv_size * local_uv;
    o.color = unpack_unorm8(inst.color);
    o.tex_slice = inst.tex_slice;

    return o;
}
