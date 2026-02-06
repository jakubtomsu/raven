Texture2DArray tex : register(t2);
SamplerState smp : register(s0);

float4 ps_main(VS_Out input, uint frontface : SV_IsFrontFace) : SV_Target {
    float3 normal = normalize(frontface ? input.normal : -input.normal);
    float4 col = input.col * tex.Sample(smp, float3(input.uv, float(input.tex_slice)));

    if (col.a < 0.01) {
        discard;
    }

    return col;
}