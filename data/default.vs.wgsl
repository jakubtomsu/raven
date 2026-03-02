@group(0) @binding(16) var<storage, read> instances : array<Mesh_Inst>;
@group(0) @binding(17) var<storage, read> verts     : array<Vertex>;

@vertex
fn vs_main(
    @builtin(vertex_index)   vid     : u32,
    @builtin(instance_index) inst_id : u32
) -> VS_Out {
    let inst = instances[inst_id + batch_consts.instance_offset];
    let vert_offs = inst.tex_slice_vert_offs >> 8;
    let vert = verts[vid + vert_offs];

    let mat = mat3x3<f32>(inst.mat_x, inst.mat_y, inst.mat_z);
    let world_pos = inst.pos + mat * vert.pos;

    let inst_color = unpack_signed_color_unorm8(inst.col);
    let vert_color = unpack_unorm8(vert.col);

    var o : VS_Out;
    o.pos       = layer_consts.view_proj * vec4<f32>(world_pos, 1.0);
    o.world_pos = world_pos;
    o.normal    = unpack_unorm8(vert.normal).xyz;
    o.uv        = vert.uv;
    o.add_col   = unpack_signed_color_unorm8(inst.add_col);
    o.col       = inst_color * vert_color;
    o.tex_slice = inst.tex_slice_vert_offs & 0xff;

    return o;
}