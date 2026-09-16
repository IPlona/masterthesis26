Shader "Custom/TestMASKSpectrum"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}

        [Treshold] _Threshold("Shade Threshold", Range(0,1)) = 0.5
        [FogColor] _FogColor("Fog Color", Color) = (0, 0, 0, 1)

        [Space]
        [Wind speed] _WindSpeed("Wind speed", float) = 0
        [Wind amplitute] _WindAmp("Wind amplitute", float) = 0
        [Wind Uniformity] _WindUni("Wind Uniformity", float) = 0
        [UV Anchor displacement] _UVAnchorDis("UV Anchor displacement", float) = 0

        [Wave Attributes] _Wave("Wave Attributes", vector) = (0, 0, 0, 1)
    }

    SubShader
    {
        Tags {
                "RenderType" = "Opaque"
                "RenderPipeline" = "UniversalPipeline"
                "LightMode" = "ForwardBase"
                //"PassFlags" = "OnlyDirectional"
                "Queue" = "Geometry"
        }
        //Level of detail??
        //LOD 200

        Pass
        {
            Name "Color Manipulation"

            Cull Off

            //May not be nessecary
            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #define _SPECULAR_COLOR
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _FORWARD_PLUS
            //#pragma multi_compile_fragment _ _SHADOWS_SOFT

            //Shadows - URP
            #pragma shader_feature_fragment _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma shader_feature_fragment _ADDITIONAL_LIGHT_SHADOWS
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //My hlsl
            #include "Assets/Materials/Shaders/ColorManipulationCalculations.hlsl"
            #include "Assets/Materials/Shaders/WindEffects.hlsl"

            //Look into this
            //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"
            
            //Appdata
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalLS     : NORMAL;   //LS = LocalSpace
                float2 uv           : TEXCOORD0;
            };

            //v2f / Varyings
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : TEXCOORD1;     //WS = WorldSpace
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD2;
                //float4 tes          : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            //TEXTURE2D(_SpectriMask);
            SAMPLER(sampler_SpectriMask);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _Threshold;
                half4 _FogColor;

                Texture2D _SpectriMask;


                float _WindSpeed;
                float _WindAmp;
                float _WindUni;
                float _UVAnchorDis;
                float4 _Wave;

            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalLS);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS);
                //OUT.tes = IN.positionOS;
                //
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                //Wave anim
                OUT.positionHCS.y += WindWave(OUT.positionWS.x, IN.uv.y + _UVAnchorDis, _WindSpeed, _WindAmp, _WindUni);

                OUT.positionHCS.x -= WaveEffect(IN.uv.x, IN.uv.y + _UVAnchorDis, _Wave);
                OUT.positionHCS.y += WaveEffect(IN.uv.x, IN.uv.y + _UVAnchorDis, _Wave);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

                //GET THE HUE COORD
                half4 colorLinear = linear2sRGB_IT(color);
                float3 colorHSV = getHSV(colorLinear);

                float mask = SAMPLE_TEXTURE2D(_SpectriMask, sampler_SpectriMask, float2(colorHSV.r, 0)).r;

                //For Saturation and Value masks, we need to convert the hueCord back to RGB (And rename the variable to colorHSV)
                //with values changed with the two masks.
                float vMask = SAMPLE_TEXTURE2D(_SpectriMask, sampler_SpectriMask, float2(colorHSV.r, 0.5)).r;
                //colorHSV.b = (colorHSV.b + vMask) - (0.4 * vMask);  //b == value
                colorHSV.b = lerp(colorHSV.b, 1.0f, step(0.01f, vMask));

                float sMask = SAMPLE_TEXTURE2D(_SpectriMask, sampler_SpectriMask, float2(colorHSV.r, 1.0)).r;
                float sMaskConditional = lerp(0, lerp(colorHSV.g, 0.45f, step(0.5f, sMask)), step(0.01f, colorHSV.g));
                colorHSV.g = sMaskConditional;  //g == saturation

                float3 newColor = sRGB2linear_IT(getRGB(colorHSV));

                color.rgb = saturate(newColor.rgb + mask * 2.5);

                //Toon pass - https://medium.com/@chitranshnishad27/toon-shaders-in-unity-from-shader-graph-to-custom-hlsl-08252b2d64a2
                float3 normal = normalize(IN.normalWS);
                float3 lightDir = normalize(_MainLightPosition.xyz);

                half4 shadow = TransformWorldToShadowCoord(IN.positionWS);
                Light mainLight = GetMainLight(shadow);
                half mainAtten = mainLight.shadowAttenuation;
                //MAfunk has fun ideas but no substance
                // IN.tes.y 
                //half MAfunk = lerp((IN.tes.y * 2) + ((IN.normalWS.y * 0.1f) * (IN.positionWS.y * 0.1f)), saturate(IN.normalWS.y * IN.positionWS.y * 0.1f + 0.5f), mainAtten);

                float NdotL = dot(normal, lightDir);
                float NdotMA = NdotL * mainAtten;

                //float shadeStep = step(_Threshold, NdotMA);
                //  Instead of hard cut we give it a bit softness
                float shadeStep = saturate(lerp(_Threshold, NdotMA, 10));

                //This is a fog effect //TODO: TURNED OFF CUZ ANNOYING IN EDIT MODE TURN BACK ON LATER
                //float fogShadow = saturate(pow(lerp(0, 1, IN.positionHCS.z * 170), -1) * 0.5f);
                //This is all calculated together
                float shadeFunk = saturate(lerp(lerp(0.2f, 0.0f, NdotL * 2), 1, shadeStep));// + fogShadow);
                
                //NOTE!!! You can calc new colors too!!! 
                //Shadow color
                half4 newShadowColor = color;
                float hueShift = saturate((lerp(0.2f, 0.0f, NdotL * 2) * 0.2f));
                colorHSV.r = lerp(colorHSV.r - hueShift, colorHSV.r + hueShift, step(0.35f, colorHSV.r));
                colorHSV.b = saturate(colorHSV.b * 0.8f);
                colorHSV.g = saturate(colorHSV.g * 1.5f);
                newShadowColor.rgb = saturate(sRGB2linear_IT(getRGB(colorHSV)).rgb + mask * 2.5);


                float4 colorToon = lerp(newShadowColor * 0.7f, color, shadeFunk);
                colorToon.a = color.a;

                return colorToon;
            }
            ENDHLSL
        }

        Pass{
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            //This saves TINY performance apparently. It skips the whole color idea
            ColorMask 0
            
            HLSLPROGRAM

            #define _SPECULAR_COLOR
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            //My
            #include "Assets/Materials/Shaders/WindEffects.hlsl"

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
            half4 _BaseColor;
            float4 _BaseMap_ST;
            half _AlphaThreshold;

            float _WindSpeed;
            float _WindAmp;
            float _WindUni;
            float _UVAnchorDis;
            float4 _Wave;

            float4 GetShadowPositionHClip(Attributes IN) {
                float3 positionWS = TransformObjectToWorld(IN.positionOS);
                float3 normalWS = TransformObjectToWorldNormal(IN.normalLS);
                //Shadow displacement
                positionWS.y += WindWave(IN.positionOS.x, IN.uv.y + _UVAnchorDis, _WindSpeed, _WindAmp, _WindUni) - 0.25f;

                positionWS.x -= WaveEffect(IN.uv.x, IN.uv.y + _UVAnchorDis, _Wave) * 0.5f;
                positionWS.y += WaveEffect(IN.uv.x, IN.uv.y + _UVAnchorDis, _Wave) * 0.5f;
                //
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection ));
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
                return 0;
            }
            ENDHLSL
            
        }
    }
}