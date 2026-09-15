Shader "Custom/TransmissionEXAMPLEShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        
        _TransparencyLM("Transmission", 2D) = "white" {}
    }

    SubShader
        {
            Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

            CGPROGRAM
            #pragma surface surf Lambert alpha

            sampler2D _BaseMap;
            fixed4 _Color;

            struct Input
            {
                float2 uv_BaseMap;
            };

            void surf(Input IN, inout SurfaceOutput o)
            {
                fixed4 c = tex2D(_BaseMap, IN.uv_BaseMap) * _Color;
                o.Albedo = c.rgb;
                o.Alpha = c.a;
            }
            ENDCG
        }

    Fallback "Transparent/VertexLit"

    SubShader
    {
        Pass{
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            Cull Off

                //This saves TINY performance apparently. It skips the whole color idea
                //ColorMask 0

                HLSLPROGRAM

                #define _SPECULAR_COLOR
                #pragma vertex vert
                #pragma fragment frag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

                float3 _LightDirection; //"Populated from URP

                struct Attributes
                {
                    float4 positionOS : POSITION;
                    float3 normalLS : NORMAL;   //LS = LocalSpace
                    float2 uv : TEXCOORD0;
                };

                struct Varyings
                {
                    float4 positionHCS : SV_POSITION;
                    float2 uv : TEXCOORD0;
                };

                TEXTURE2D(_BaseMap);
                SAMPLER(sampler_BaseMap);
                float4 _BaseMap_ST;
                half _AlphaThreshold;

                float4 GetShadowPositionHClip(Attributes IN) {
                    float3 positionWS = TransformObjectToWorld(IN.positionOS);
                    float3 normalWS = TransformObjectToWorldNormal(IN.normalLS);
                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                    positionCS = ApplyShadowClamping(positionCS);
                    return positionCS;
                }

                Varyings vert(Attributes IN)
                {
                    Varyings OUT;
                    OUT.uv = (IN.uv * _BaseMap_ST.xy) + _BaseMap_ST.zw;
                    OUT.positionHCS = GetShadowPositionHClip(IN);

                    return OUT;
                }

                half4 frag(Varyings IN) : SV_Target
                {
                    float a = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).a;
                    if (a < _AlphaThreshold) {
                        discard;
                    }
                    return 0;
                }
                ENDHLSL

            }
    }
}
