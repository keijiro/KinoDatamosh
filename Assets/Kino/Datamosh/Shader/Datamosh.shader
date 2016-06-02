//
// Kino/Datamosh - Glitch effect simulating video compression artifacts
//
// Copyright (C) 2016 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
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
    float4 _MainTex_TexelSize;

    sampler2D _WorkTex;
    float4 _WorkTex_TexelSize;

    sampler2D _DispTex;
    float4 _DispTex_TexelSize;

    sampler2D_half _CameraMotionVectorsTexture;
    float4 _CameraMotionVectorsTexture_TexelSize;

    float _BlockSize;
    float _Quality;
    float _Velocity;
    float _Diffusion;

    // PRNG
    float UVRandom(float2 uv)
    {
        float f = dot(float2(12.9898, 78.233), uv);
        return frac(43758.5453 * sin(f));
    }

    // Vertex shader for multi texturing
    struct v2f_multitex
    {
        float4 pos : SV_POSITION;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
    };

    v2f_multitex vert_multitex(appdata_full v)
    {
        v2f_multitex o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv0 = v.texcoord.xy;
        o.uv1 = v.texcoord.xy;
    #if UNITY_UV_STARTS_AT_TOP
        if (_MainTex_TexelSize.y < 0.0)
            o.uv1.y = 1.0 - v.texcoord.y;
    #endif
        return o;
    }

    // Simply-clear-them-all shader
    half4 frag_init(v2f_img i) : SV_Target
    {
        return 0;
    }

    // Displacement buffer updating shader
    half4 frag_update(v2f_img i) : SV_Target
    {
        float2 uv = i.uv;
        float2 t0 = float2(_Time.y, 0);

        // motion vector
        half2 mv = tex2D(_CameraMotionVectorsTexture, uv).rg;
        mv *= _Velocity;

        // normalized coordinates -> pixel coordinates
        mv = mv * _ScreenParams.xy;

        // small random displacement
        float2 rmv = float2(
            UVRandom(uv + t0.xy),
            UVRandom(uv + t0.yx)
        );
        mv += (rmv - 0.5) * _Diffusion;

        // pixel perfect snap
        mv = round(mv);

        // motion accumulation in alpha channel
        half alpha = tex2D(_MainTex, i.uv).a;
        alpha += length(mv) * (pow(_Quality, 2) + 0.1) * 0.01;
        alpha += UVRandom(uv - t0.xx) * pow(_Quality, 10) * 0.02;

        // pixel coordinates -> normalized coordinates
        mv *= (_ScreenParams.zw - 1);

        // random number (changing by displacement)
        half rnd = UVRandom(uv + dot(mv, 1));

        return half4(mv, rnd, alpha);
    }

    // Moshing shader
    half4 frag_mosh(v2f_multitex i) : SV_Target
    {
        half4 disp = tex2D(_DispTex, i.uv0);
        half4 src  = tex2D(_MainTex, i.uv1);
        half4 work = tex2D(_WorkTex, i.uv1 - disp.xy * 0.98); // make it dirty!

        // make DCT basis-ish noise pattern
        float2 uv = i.uv1 * _DispTex_TexelSize.zw;
        uv *= ceil(disp.z * 4) * (UNITY_PI * 4);

        float axis = 0.5 < frac(disp.z * 17.371356);

        float dct = cos(lerp(uv.x, uv.y, axis)); 
        dct *= frac(disp.z * 3305.121);

        // apply the DCT-ish noise when the motion is accumulated
        dct *= disp.a > 0.8 - 0.3 * _Quality;
        work.rgb = lerp(work.rgb, src.rgb, dct);

        // cancel the noise when the motion is much accumulated
        half clean = disp.a > (1 / (_Quality + 0.02));
        half3 rgb = lerp(work.rgb, src.rgb, clean);

        return half4(rgb, src.a);
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
            #pragma vertex vert_multitex
            #pragma fragment frag_mosh
            #pragma target 3.0
            ENDCG
        }
    }
}
