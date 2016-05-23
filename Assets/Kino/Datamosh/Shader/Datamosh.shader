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
    float _VelocityScale;

    // PRNG
    float UVRandom(float2 uv)
    {
        float f = dot(float2(12.9898, 78.233), uv);
        return frac(43758.5453 * sin(f));
    }

    // Clears working buffer.
    half4 frag_init(v2f_img i) : SV_Target
    {
        return 0;
    }

    // Updates displacement buffer.
    half4 frag_update(v2f_img i) : SV_Target
    {
        float2 uv = i.uv;
        float2 t0 = float2(_Time.y, 0);

        // motion vector
        half2 mv = tex2D(_CameraMotionVectorsTexture, uv).rg;
        mv *= _VelocityScale;

        // normalized coordinates -> pixel coordinates
        mv = mv * _ScreenParams.xy;

        // small random displacement
        float2 rmv = float2(
            UVRandom(uv + t0.xy),
            UVRandom(uv + t0.yx)
        );
        mv += (rmv - 0.5) * 0.0;

        // pixel perfect snap
        mv = round(mv);

        // alpha value (0 = moshing, 1 = clean)
        half alpha = tex2D(_MainTex, i.uv).a;

        // keep moshing while the amount of the displacement is
        // lower than the threshold.
        float thresh = _BlockSize * (0.2 + 5 * UVRandom(uv - t0.xx));
        alpha += any(abs(mv) > thresh);

        // pixel coordinates -> normalized coordinates
        mv *= (_ScreenParams.zw - 1);

        return half4(mv, 0, alpha > 0);
    }

    // Moshing!
    half4 frag_mosh(v2f_img i) : SV_Target
    {
        half4 disp = tex2D(_DispTex, i.uv);
        half4 src  = tex2D(_MainTex, i.uv);
        half4 work = tex2D(_WorkTex, i.uv - disp.xy);
        return half4(lerp(work.rgb, src.rgb, disp.a), src.a);
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
            #pragma fragment frag_update
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
