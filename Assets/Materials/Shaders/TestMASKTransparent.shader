Shader "Custom/TestMASKTransparent"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}

        [Treshold] _Threshold("Shade Threshold", Range(0,1)) = 0.5
        [FogColor] _FogColor("Fog Color", Color) = (0, 0, 0, 1)

        [Alpha cutoff] _AlphaThreshold("Alpha Cutoff", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags {
                "RenderType" = "Transparent"
                "RenderPipeline" = "UniversalPipeline"
                "Queue" = "Transparent"
        }
        //Level of detail??
        //LOD 200

        Pass
        {
            Name "Color Manipulation"

            //Enable transparency
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            //Enable backface culling
            Cull Off    

            //May not be nessecary
            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #define _SPECULAR_COLOR
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _FORWARD_PLUS

            //Shadows - URP
            #pragma shader_feature_fragment _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma shader_feature_fragment _ADDITIONAL_LIGHT_SHADOWS
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
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
                float3 normalWS     : TEXCOORD0;     //WS = WorldSpace
                float2 uv           : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
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

            CBUFFER_END

            float4 linear2sRGB_IT(half4 c) {
                //Based on the calculations of Ian Taylor in: https://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html?m=1
                half4 s1 = sqrt(c);
                half4 s2 = sqrt(s1);
                half4 s3 = sqrt(s2);

                return (0.585122381 * s1 + 0.783140355 * s2 - 0.368262736 * s3);
            }
            float3 sRGB2linear_IT(float3 c) {
                //Based on the calculations of Ian Taylor in: https://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html?m=1
                return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
            }

            float3 RGBtoHCV(in float3 RGB)
            {
                //From Ian Taylor: https://www.chilliant.com/rgb2hsvx.html
                float Epsilon = 1e-10;
                // Based on work by Sam Hocevar and Emil Persson
                float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0 / 3.0) : float4(RGB.gb, 0.0, -1.0 / 3.0);
                float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
                float C = Q.x - min(Q.w, Q.y);
                float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
                return float3(H, C, Q.x);
            }
            float3 getHSV(half4 RGB) {
                //Bsed on Ian Taylor: https://www.chilliant.com/rgb2hsvx.html
                float Epsilon = 1e-10;
                
                float3 HCV = RGBtoHCV(RGB);
                float S = HCV.y / (HCV.z + Epsilon);
                return float3(HCV.x, S, HCV.z);
            }

            float3 getRGB(float3 c) {
                //Code credit to Patapom (https://stackoverflow.com/a/19400360), under CC BY-SA 3.0, aka. sharing (commercial) and editing is fine.

                //This is mising the "if saturation is 0 statement TODOOOO
                if (c.y <= 0) {
                    return c.z;
                }

                //In the getHSV we do similiar conversions, but this is essential to ensure that the code works as should.
                c.x = fmod(100.0 + c.x, 1.0);

                float hueSlice = 6.0 * c.x;
                float hueSliceInteger = floor(hueSlice);                //Floor returns nearest full integer, aka. 1.2 -> 1, 3.9 -> 3
                float hueSliceInterpolant = hueSlice - hueSliceInteger;

                //By the comment + Nikolai Waldman https://www.niwa.nu/2013/05/math-behind-colorspace-conversions-rgb-hsl/
                // we can start by doing temporary values.
                float3 tempRGB = float3(c.z * (1.0 - c.y),
                                        c.z * (1.0 - c.y * hueSliceInterpolant),
                                        c.z * (1.0 - c.y * (1.0 - hueSliceInterpolant)));
                
                //Patapom had pinpointed pattern in common HSVtoRGB functions, where switch/if-statem was used to determine
                // how each r g an b value should be calculated, noticing that every other "region" (aka. section in the color wheel)
                // wsa just shifted/rotated pattern, like so (x, y, z) to (z, x, y) to (y, z, x)
                // In the even parts the pattern to shift was (Value, Blue, Red) and uneven (Green, Value, Red)
                //
                // On additional note, one might recognize the correlation between "every other section" in Hue wheel
                // to the HSV color wheel being made off primary (RGB) and secondary (CYM) colors.
                float isOddSlice = fmod(hueSliceInteger, 2.0);
                float threeSliceSelector = 0.5 * (hueSliceInteger - isOddSlice);

                float3 shiftingRGBForEvenSlices = float3(c.z, tempRGB.zx);
                float3 shiftingRGBForOddSlice = float3(tempRGB.y, c.z, tempRGB.x);

                float3 shiftingRGB = lerp(shiftingRGBForEvenSlices, shiftingRGBForOddSlice, isOddSlice);
                //This is "how we choose if to use (V, B, R) pattern or (G, V, R) pattern. If isOddSlice = 0, we choose first, if 1 we choose second.

                float isNotFirst = saturate(threeSliceSelector);        //Similiarly as above using fmod and lerp to make if-statement
                float isNotSecond = saturate(threeSliceSelector - 1.0);

                float3 newRGB = lerp(shiftingRGB.xyz, lerp(shiftingRGB.zxy, shiftingRGB.yzx, isNotSecond), isNotFirst);
                //And done... Again.

                return newRGB;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalLS);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS);
                //
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

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
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection ));
                positionCS = ApplyShadowClamping(positionCS);
                return positionCS;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = GetShadowPositionHClip(IN);
                OUT.uv = (IN.uv * _BaseMap_ST.xy) + _BaseMap_ST.zw;

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