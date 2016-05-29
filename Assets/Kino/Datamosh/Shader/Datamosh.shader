//
// Kino/Datamosh - Video compression artifact effect
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
        half2 mv = tex2D(_CameraMotionVectorsTexture, uv).rg * _Velocity;

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

        // alpha value (0 = moshing, 1 = clean)
        half alpha = tex2D(_MainTex, i.uv).a;

        // keep moshing while the amount of the displacement is
        // lower than the threshold.
        //float thresh = _BlockSize * (0.5 + UVRandom(uv - t0.xx));
        //alpha += any(abs(mv * _Quality) > thresh);
        alpha = min(100, alpha + length(mv * _Quality * 0.02) + UVRandom(uv - t0.xx) * _Quality * 0.01);

        // pixel coordinates -> normalized coordinates
        mv *= (_ScreenParams.zw - 1);

        //return half4(mv, 0, alpha > 0);
        return half4(mv, 0, alpha);
    }

    // Moshing!
    half4 frag_mosh(v2f_img i) : SV_Target
    {
        half4 disp = tex2D(_DispTex, i.uv);
        half4 src  = tex2D(_MainTex, i.uv);
        half4 work = tex2D(_WorkTex, i.uv - disp.xy * 0.98);

        float2 uv = i.uv.xy * _ScreenParams.xy * 0.8;
        float lv = lerp(sin(uv.x), sin(uv.y), UVRandom(floor(uv * _DispTex_TexelSize.xy) * _DispTex_TexelSize.zw + disp.x + disp.y));

        //work.rgb = saturate(work.rgb + (half3)(src.rgb) * 0.1 * lv * disp.a);
        work.rgb = lerp(work.rgb, src.rgb, lv * (disp.a > 1 - 0.5 * _Quality));

        //return half4(work.rgb, src.a);

        return half4(lerp(work.rgb, src.rgb, disp.a > (1.0 / (_Quality + 0.00001) - 0.05)), src.a);
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
