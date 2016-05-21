Shader "Hidden/Kino/Datamosh"
{
    Properties
    {
        _MainTex("", 2D) = ""{}
        _MotionTex("", 2D) = ""{}
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    sampler2D _MotionTex;
    sampler2D_half _CameraMotionVectorsTexture;

    half4 frag_prepare(v2f_img i) : SV_Target
    {
        half2 mv = tex2D(_CameraMotionVectorsTexture, i.uv).rg;
        return half4(mv, 0, 0);
    }

    half4 frag_mosh(v2f_img i) : SV_Target
    {
        half2 mv = tex2D(_MotionTex, i.uv).rg;
        mv = round(mv * 300) / 300;
        return tex2D(_MainTex, i.uv - mv / 2);
    }

    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
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
