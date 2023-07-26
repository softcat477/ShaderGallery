Shader "Custom/ValueNoise"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _NoiseFrequency ("Noise Frequency", float) = 1.0
        _NoiseOctave ("Noise Octave", int) = 0
        _Speed ("Speed", float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:myvert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float3 localPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _NoiseFrequency;
        int _NoiseOctave;
        float _Speed;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float noise1d(float2 x) {
            return frac(sin(x * 78.233) * 43758.5453);
        }

        float noise2d(float2 uv) {
            return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
        }

        float noise3d(float3 xyz) {
            return frac(sin(dot(xyz, float3(12.9898, 78.233, 37.719))) * 43758.5453);
        }

        float valueNoise1d(float fraction) {
            float valLeft = noise1d(floor(fraction));
            float valRight = noise1d(ceil(fraction));

            int power = 3;
            float ein = pow(frac(fraction), power);
            float eout = pow(frac(fraction)-1, power)+1;
            float intp = lerp(ein, eout, frac(fraction));
            float val = lerp(valLeft, valRight, intp);

            return val;
        }

        float valueNoise2d(float2 fraction) {
            int power = 3;
            float frac_x = fraction.x;
            float frac_y = fraction.y;
            float ein, eout, intp;

            float lx = floor(fraction.x);
            float rx = ceil(fraction.x);
            float ly = floor(fraction.y);
            float uy = ceil(fraction.y);

            // Get noise for four corners
            float valLowerLeft = noise2d(float2(lx, ly));
            float valLowerRight = noise2d(float2(rx, ly));
            float valUpperLeft = noise2d(float2(lx, uy));
            float valUpperRight = noise2d(float2(rx, uy));

            // Interpolate horizontally
            ein = pow(frac(frac_x), power);
            eout = pow(frac(frac_x)-1, power)+1;
            intp = lerp(ein, eout, frac(frac_x));
            float intp_val_lower = lerp(valLowerLeft, valLowerRight, intp);
            float intp_val_upper = lerp(valUpperLeft, valUpperRight, intp);

            // Interpolate vertically
            ein = pow(frac(frac_y), power);
            eout = pow(frac(frac_y)-1, power)+1;
            intp = lerp(ein, eout, frac(frac_y));
            float intp_val = lerp(intp_val_lower, intp_val_upper, intp);

            return intp_val;
        }

        float valueNoise3d(float3 fraction) {
            int power = 3;
            float frac_x = fraction.x;
            float frac_y = fraction.y;
            float frac_z = fraction.z;
            float ein, eout, intp;

            float x1 = floor(fraction.x);
            float x2 = ceil(fraction.x);
            float y1 = floor(fraction.y);
            float y2 = ceil(fraction.y);
            float z1 = floor(fraction.z); // lower z
            float z2 = ceil(fraction.z); // upper z


            // Get noise for eight corners
            float x1y1z1 = noise3d(float3(x1, y1, z1));
            float x1y2z1 = noise3d(float3(x1, y2, z1));
            float x1y1z2 = noise3d(float3(x1, y1, z2));
            float x1y2z2 = noise3d(float3(x1, y2, z2));
            float x2y1z1 = noise3d(float3(x2, y1, z1));
            float x2y2z1 = noise3d(float3(x2, y2, z1));
            float x2y1z2 = noise3d(float3(x2, y1, z2));
            float x2y2z2 = noise3d(float3(x2, y2, z2));

            // Reduce X dim
            ein = pow(frac(frac_x), power);
            eout = pow(frac(frac_x)-1, power)+1;
            intp = lerp(ein, eout, frac(frac_x));
            float y1z1 = lerp(x1y1z1, x2y1z1, intp);
            float y1z2 = lerp(x1y1z2, x2y1z2, intp);
            float y2z1 = lerp(x1y2z1, x2y2z1, intp);
            float y2z2 = lerp(x1y2z2, x2y2z2, intp);

            // Reduce y
            ein = pow(frac(frac_y), power);
            eout = pow(frac(frac_y)-1, power)+1;
            intp = lerp(ein, eout, frac(frac_y));
            float _z1 = lerp(y1z1, y2z1, intp);
            float _z2 = lerp(y1z2, y2z2, intp);

            // Reduce z
            ein = pow(frac(frac_z), power);
            eout = pow(frac(frac_z)-1, power)+1;
            intp = lerp(ein, eout, frac(frac_z));
            float intp_val = lerp(_z1, _z2, intp);

            return intp_val;
        }

        float4 paintValueNoise1d(float3 vertex_world, float3 vertex_local) {
            float fraction = vertex_world.x  * _NoiseFrequency * pow(2, _NoiseOctave);
            float noise = valueNoise1d(fraction);

            float fil = abs(noise - vertex_local.z);
            fil = smoothstep(0, 0.1, fil);

            return half4(fil, fil, fil, 1);
        }

        float4 paintValueNoise2d(float2 vertex_world) {

            float2 fraction = vertex_world * _NoiseFrequency * pow(2, _NoiseOctave);
            float noise = valueNoise2d(fraction);
            return half4(noise, noise, noise, 1);
        }

        float4 paintValueNoise3d(float3 vertex_world) {

            float3 fraction = vertex_world * _NoiseFrequency * pow(2, _NoiseOctave);
            float noise = valueNoise3d(fraction);
            return half4(noise, noise, noise, 1);
        }

        void myvert(inout appdata_full v, out Input data) {
            UNITY_INITIALIZE_OUTPUT(Input, data);
            data.uv_MainTex = v.normal;
            data.worldPos = UnityObjectToClipPos(v.vertex);
            data.localPos = v.vertex;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            float4 noise =  paintValueNoise3d(IN.worldPos + _Time.x * _Speed);
            o.Albedo = noise.rgb;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
