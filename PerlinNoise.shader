Shader "Custom/PerlinNoise"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _NoiseFrequency ("Noise Frequency", float) = 1.0
        _NoiseOctave ("Noise Octave", int) = 0

        _Speed("Speed", float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _Speed;

        float _NoiseOctave;
        float _NoiseFrequency;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float2 noise2d2d(float2 uv) {
            float2 ret = float2(frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453),
                frac(cos(dot(uv, float2(12.9898, 78.233))) * 43758.5453));

            ret = ret * 2 - 1.0; // from 0~1 to -1~1
            ret = normalize(ret);
            return ret;
        }

        float noise3d3d(float3 xyz) {
            float3 ret = float3(
                frac(sin(dot(xyz, float3(12.9898, 78.233, 45.543))) * 43758.5453),
                frac(sin(dot(xyz, float3(54.123, 43.543, 32.989))) * 43758.5453),
                frac(sin(dot(xyz, float3(93.989, 43.242, 65.654))) * 43758.5453)
            );

            ret = ret * 2 - 1.0; // from 0~1 to -1~1
            ret = normalize(ret);

            return ret;
        }

        float gradientDot2d(float2 gradient_xy, float2 xy) {
            float2 gradient = noise2d2d(gradient_xy);
            float2 offset = xy - gradient_xy;
            return dot(gradient, offset);
        }

        float gradientDot3d(float3 gradient_xyz, float3 xyz) {
            float3 gradient = noise3d3d(gradient_xyz);
            float3 offset = xyz - gradient_xyz;
            return dot(gradient, offset);
        }

        float2 perlinNoise2d(float2 fraction) {
            float frac_x = fraction.x;
            float frac_y = fraction.y;
            float ein, eout, intp;

            float x1 = floor(fraction.x);
            float x2 = ceil(fraction.x);
            float y1 = floor(fraction.y);
            float y2 = ceil(fraction.y);

            // 1. Dot product of random gradient on four corners
            float x1y1 = gradientDot2d(float2(x1, y1), fraction);
            float x1y2 = gradientDot2d(float2(x1, y2), fraction);
            float x2y1 = gradientDot2d(float2(x2, y1), fraction);
            float x2y2 = gradientDot2d(float2(x2, y2), fraction);

            // Lerp x
            ein = frac(frac_x);
            ein = 6 * pow(ein, 5) - 15 * pow(ein, 4) + 10 * pow(ein, 3);
            float _y1 = lerp(x1y1, x2y1, ein);
            float _y2 = lerp(x1y2, x2y2, ein);

            // Lerp y
            ein = frac(frac_y);
            ein = 6 * pow(ein, 5) - 15 * pow(ein, 4) + 10 * pow(ein, 3);
            float ret = lerp(_y1, _y2, ein);

            return ret * 0.5 + 0.5;
        }

        float4 paintPerlinNoise2d(float2 vertex_world) {

            float2 fraction = vertex_world * _NoiseFrequency * pow(2, _NoiseOctave);
            float noise = perlinNoise2d(fraction);
            return half4(noise, noise, noise, 1);
        }

        float2 perlinNoise3d(float3 fraction) {
            float frac_x = fraction.x;
            float frac_y = fraction.y;
            float frac_z = fraction.z;
            float ein, eout, intp;

            float x1 = floor(fraction.x);
            float x2 = ceil(fraction.x);
            float y1 = floor(fraction.y);
            float y2 = ceil(fraction.y);
            float z1 = floor(fraction.z);
            float z2 = ceil(fraction.z);

            // 1. Dot product of random gradient on four corners
            float x1y1z1 = gradientDot3d(float3(x1, y1, z1), fraction);
            float x1y1z2 = gradientDot3d(float3(x1, y1, z2), fraction);
            float x1y2z1 = gradientDot3d(float3(x1, y2, z1), fraction);
            float x1y2z2 = gradientDot3d(float3(x1, y2, z2), fraction);
            float x2y1z1 = gradientDot3d(float3(x2, y1, z1), fraction);
            float x2y1z2 = gradientDot3d(float3(x2, y1, z2), fraction);
            float x2y2z1 = gradientDot3d(float3(x2, y2, z1), fraction);
            float x2y2z2 = gradientDot3d(float3(x2, y2, z2), fraction);

            // Lerp x
            ein = frac(frac_x);
            ein = 6 * pow(ein, 5) - 15 * pow(ein, 4) + 10 * pow(ein, 3);
            float y1z1 = lerp(x1y1z1, x2y1z1, ein);
            float y1z2 = lerp(x1y1z2, x2y1z2, ein);
            float y2z1 = lerp(x1y2z1, x2y2z1, ein);
            float y2z2 = lerp(x1y2z2, x2y2z2, ein);

            // Lerp y
            ein = frac(frac_y);
            ein = 6 * pow(ein, 5) - 15 * pow(ein, 4) + 10 * pow(ein, 3);
            float _z1 = lerp(y1z1, y2z1, ein);
            float _z2 = lerp(y1z2, y2z2, ein);

            // Lerp y
            ein = frac(frac_z);
            ein = 6 * pow(ein, 5) - 15 * pow(ein, 4) + 10 * pow(ein, 3);
            float ret = lerp(_z1, _z2, ein);

            return ret * 0.5 + 0.5;
        }

        float4 paintPerlinNoise3d(float3 vertex_world) {
            float3 fraction = vertex_world * _NoiseFrequency * pow(2, _NoiseOctave);
            float noise = perlinNoise3d(fraction);
            return half4(noise, noise, noise, 1);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            float4 noise = paintPerlinNoise3d(IN.worldPos + _Time.x * _Speed);
            o.Albedo = noise;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
