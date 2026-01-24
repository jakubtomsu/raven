StructuredBuffer<Mesh_Inst> instances : register(t0);
StructuredBuffer<Vertex> verts : register(t1);

VS_Out vs_main(uint vid : SV_VertexID, uint inst_id : SV_InstanceID) {
    Mesh_Inst inst = instances[inst_id + instance_offset];
    Vertex vert = verts[vid + inst.vert_offs];

    float3x3 mat = float3x3(inst.mat_x, inst.mat_y, inst.mat_z);

    VS_Out o;
    float3 world_pos = inst.pos + mul(mat, vert.pos);
    o.pos = mul(view_proj, float4(world_pos, 1.0f));
    o.world_pos = world_pos;
    o.normal = unpack_unorm8(vert.normal).xyz; // * adjugate
    o.uv = vert.uv;
    o.color = unpack_unorm8(inst.color);
    o.color.rgb *= unpack_unorm8(vert.color).rgb;
    o.tex_slice = inst.tex_slice;

    return o;
}