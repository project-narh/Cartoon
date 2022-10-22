Shader "Custom/Cartoon"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _OutlineColor("Outline Color", Color) = (0,0,0,0)
        _Outlinesize("Outline", Range(0, 0.2)) = 0.05
        _ToonNum("Toon", Range(1,10)) = 4
        _highlight("highlight", Range(1, 500)) = 100
        _Rimsize("Rim size", Range(10,30)) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        cull Front
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            fixed4 _OutlineColor;
            float _Outlinesize;

            struct read
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct write
            {
                float4 vertex : SV_POSITION;
            };

            write vert(read r)
            {
                write w;
                float3 pos = r.vertex + normalize(r.normal) * _Outlinesize;
                w.vertex = UnityObjectToClipPos(pos);
                return w;
            }

            float4 frag(write i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }

        cull Back
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Toon

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };
        float _ToonNum;
        float _highlight;
        float _Rimsize;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float4 LightingToon(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
        {
            float3 normal = normalize(s.Normal);
            float diffuse = (dot(normal, lightDir)) * 0.5 + 0.5;
            float specular = (2 * normal) * dot(lightDir, normal) - lightDir;
            specular = dot(specular, viewDir);
            specular = pow(specular, _highlight);
            specular = smoothstep(0, 0.05f, specular);
            float rim = 1 - saturate(dot(viewDir, normal));
            rim = pow(rim, _Rimsize);

            diffuse = ceil(diffuse * _ToonNum) / _ToonNum;

            float4 total;
            total.rgb = s.Albedo * _Color * (diffuse + specular * rim) * _LightColor0;
            total.a = s.Alpha;
            return total;
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = 1.0f;
        }

        ENDCG
    }
}
