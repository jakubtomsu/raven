@group(0) @binding(18)
var tex : texture_2d_array<f32>;

@group(0) @binding(0)
var smp : sampler;

@fragment
fn ps_main(
    input : VS_Out,
    @builtin(front_facing) frontface : bool,
) -> @location(0) vec4<f32> {

    let normal = normalize(
        select(-input.normal, input.normal, frontface)
    );

    let col =
        input.color *
        textureSample(tex, smp, input.uv, i32(input.tex_slice));

    if (col.a < 0.01) {
        discard;
    }

    return col;
}
