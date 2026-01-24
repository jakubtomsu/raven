@group(0) @binding(16) var<storage, read> instances : array<Mesh_Inst>;
@group(0) @binding(17) var<storage, read> verts     : array<Vertex>;

@vertex
fn vs_main(
    @builtin(vertex_index)   vid     : u32,
    @builtin(instance_index) inst_id : u32
) -> VS_Out {
    let inst = instances[inst_id + batch_consts.instance_offset];
    let vert = verts[vid + inst.vert_offs];

    let world_pos = inst.pos + (inst.mat * vert.pos);

    var o : VS_Out;
    o.pos       = layer_consts.view_proj * vec4<f32>(world_pos, 1.0);
    o.world_pos = world_pos;
    o.normal    = unpack_unorm8(vert.normal).xyz;
    o.uv        = vert.uv;

    let inst_color = unpack_unorm8(inst.color);
    let vert_color = unpack_unorm8(vert.color);
    o.color        = vec4<f32>(inst_color.rgb * vert_color.rgb, inst_color.a);

    o.tex_slice = inst.tex_slice;
    return o;
}