Shader "Custom/SkyboxCustomShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        //[MainTexture] _BaseMap("Base Map", 2D) = "white" {}

        [Gradient Height] _GHeight("Gradient Height", Range(-2, 2)) = 0
        [Gradient Power] _GPower("Gradient Power", float) = 1

        [Sun Color] _SunColor("Sun Color", Color) = (1, 1, 1, 1)
        [Sky Color] _SkyColor("Sky Color", Color) = (.5, .5, .5, 1)
        [Ground Color] _GroundColor("Ground", Color) = (.369, .349, .341, 1)

        [Sun Radius] _SunRad ("Sun Radius", Range(0,0.999)) = 1
        [Sun Hardness] _SunHar ("Sun hardness", Range(1,100)) = 100
        [Sun Luminasity] _SunLum ("Sun Luminasity", Range(0,1.5)) = 1
    }

    SubShader
    {
        Tags {  "RenderType" = "Background" 
                "Queue"="Background" 
                "PreviewType" = "Skybox"
                "RenderPipeline" = "UniversalPipeline" 
        }
        Cull Off
        ZWrite Off
        ZClip False

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //My hlsl
            #include "Assets/Materials/Shaders/ColorManipulationCalculations.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 viewDirWS    : TEXCOORD0;   //WS = Worldspace
                float3 lightDir     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;

                Texture2D _SpectriMask;

                half4 _SunColor;
                half4 _SkyColor;
                half4 _GroundColor;

                float _SunRad, _SunHar, _SunLum, _GHeight, _GPower;
            CBUFFER_END

            SAMPLER(sampler_SpectriMask);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);

                OUT.positionHCS = vertexInput.positionCS;
                OUT.viewDirWS = vertexInput.positionWS;

                OUT.positionWS = IN.positionOS.xyz;

                Light light = GetMainLight();
                OUT.lightDir = light.direction;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = _BaseColor;
                
                float3 viewDir = normalize(IN.viewDirWS);

                //Sun + its color
                half sun = dot(IN.lightDir, viewDir);
                half4 sunFallOff = saturate(lerp(_SunRad * 1.01f, sun, _SunHar ));
                half4 sunLumi = saturate(lerp(_SunRad, sun, _SunLum * 10)) * 0.6f;
                
                half4 SunMask = smoothstep(0, 1, sunFallOff) + smoothstep(0, 1, sunLumi);
                
                //These colors should be HDR, but I think I will just disable HDR
                //We will "mask" the colors here now.
                // Basically, we will get hue, get the mask for each hue, and then give conditional.

                float3 gColHSV = getHSV(_GroundColor);
                float Gmask = SAMPLE_TEXTURE2D(_SpectriMask, sampler_SpectriMask, float2(gColHSV.r, 0)).r;
                half4 GroundCol = lerp(_BaseColor, _GroundColor, step(Gmask, 0.01f));

                float3 sColHSV = getHSV(_SkyColor);
                float Smask = SAMPLE_TEXTURE2D(_SpectriMask, sampler_SpectriMask, float2(sColHSV.r, 0)).r;
                half4 SkyCol = lerp(_BaseColor, _SkyColor, step(Smask, 0.01f));
                
                float3 sunColHSV = getHSV(_SunColor);
                float SCmask = SAMPLE_TEXTURE2D(_SpectriMask, sampler_SpectriMask, float2(sunColHSV.r, 0)).r;
                //Sun won't use the "_BaseColor", because... well, that would make sun disappear. So we use white.
                half4 SunCol = lerp((1, 1, 1, 1), _SunColor, step(SCmask, 0.01f));
                
                //Gradient to horizont
                color = lerp(GroundCol, SkyCol, IN.positionWS.y * _GPower + _GHeight);

                return saturate(lerp(color, SunCol, SunMask) + step(_SunRad, sun));
            }
            ENDHLSL
        }
    }


}
