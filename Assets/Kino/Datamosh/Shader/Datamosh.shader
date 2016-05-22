Shader "Hidden/Kino/Datamosh"
{
    Properties
    {
        _MainTex("", 2D) = ""{}
        _WorkTex("", 2D) = ""{}
        _MotionTex("", 2D) = ""{}
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    sampler2D _WorkTex;
    sampler2D _MotionTex;

    sampler2D_half _CameraMotionVectorsTexture;
    float4 _CameraMotionVectorsTexture_TexelSize;

    float _BlockSize;

    half4 frag_init(v2f_img i) : SV_Target
    {
        half3 c = tex2D(_MainTex, i.uv).rgb;
        return half4(c, 1);
    }

    half4 frag_prepare(v2f_img i) : SV_Target
    {
        half2 mv = tex2D(_CameraMotionVectorsTexture, i.uv).rg;
        mv = round(mv * _ScreenParams.xy) * (_ScreenParams.zw - 1);
        return half4(mv, 0, 0);
    }

    half4 frag_mosh(v2f_img i) : SV_Target
    {
        half2 mv = tex2D(_MotionTex, i.uv).rg;
        half4 sc = tex2D(_MainTex, i.uv);
        half4 mc = tex2D(_WorkTex, i.uv - mv * 0.95);
        half4 mc2 = tex2D(_WorkTex, i.uv);

        half alpha = mc.a * mc2.a * any(abs(mv) < ((_ScreenParams.zw - 1) * _BlockSize * 1.5));
        alpha = alpha > 0.1;

        return half4(lerp(sc.rgb, mc.rgb, alpha), alpha);
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
