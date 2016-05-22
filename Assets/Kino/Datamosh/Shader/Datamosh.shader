Shader "Hidden/Kino/Datamosh"
{
    Properties
    {
        _MainTex("", 2D) = ""{}
        _WorkTex("", 2D) = ""{}
        _DispTex("", 2D) = ""{}
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    sampler2D _WorkTex;
    sampler2D _DispTex;

    sampler2D_half _CameraMotionVectorsTexture;
    float4 _CameraMotionVectorsTexture_TexelSize;

    float _BlockSize;

    half4 frag_init(v2f_img i) : SV_Target
    {
        return 0;
    }

// Pseudo random number generator with 2D argument
float UVRandom(float u, float v)
{
    float f = dot(float2(12.9898, 78.233), float2(u, v));
    return frac(43758.5453 * sin(f));
}

    half4 frag_prepare(v2f_img i) : SV_Target
    {
        half alpha = tex2D(_MainTex, i.uv).a;

        half2 mv = tex2D(_CameraMotionVectorsTexture, i.uv).rg;
        mv = round(mv * _ScreenParams.xy);

        alpha += any(abs(mv) > _BlockSize * (0.3 + 10 * UVRandom(i.uv.x, i.uv.y + _Time.y)));

        mv *= (_ScreenParams.zw - 1);

        return half4(mv, 0, alpha > 0);
    }

    half4 frag_mosh(v2f_img i) : SV_Target
    {
        half4 d = tex2D(_DispTex, i.uv);

        half4 c0 = tex2D(_MainTex, i.uv);
        half4 c1 = tex2D(_WorkTex, i.uv - d.xy * 0.6);

        return half4(lerp(c1.rgb, c0.rgb, d.a), c0.a);
    }

    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_init
            #pragma target 3.0
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_prepare
            #pragma target 3.0
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_mosh
            #pragma target 3.0
            ENDCG
        }
    }
}
