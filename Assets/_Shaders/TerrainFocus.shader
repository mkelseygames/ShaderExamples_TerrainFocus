// mkelsey - TerrainFocus. 
// Surface shader, originally designed to construct a miniature
// optimised terrain space, with an area of alpha focus.
// -> Reduced to contour specialisation on a pre-existing surface.

// Note: Rim Lighting, Tesselation & Displacement Removed.

Shader "Custom/TerrainFocus"
 {
    Properties 
    {
        [Header(Texture and Color)] [Space(5)]
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Color ("Color", color) = (1,1,1,1)

        // Contour Lines
        [Space(10)] [Header(Contour Lines)] [Space(5)]
        _TerrainHeight ("Terrain Height", Range(0.0, 10.0)) = 0.5
        _TerrainOffsetX ("Terrain Offset X", Range(-2.0, 2.0)) = 0.0
        _TerrainOffsetZ ("Terrain Offset Z", Range(-2.0, 2.0)) = 0.0
        _ContourLayerHeight ("Layer Height", Range(1.0, 50.0)) = 10.0
        _ContourLayerSections ("Layer Sections", Int) = 4
        _ContourOffset ("Terrain Lines Y Offset", Range(0.0, 1.0)) = 0.0
        _ContourLineSize ("Line Size", Range(0.0, 100.0)) = 0.1
        _ContourAlpha ("Overall Alpha", Range(0.0, 1.0)) = 1.0
        _ContourSectionAlpha ("Section Alpha", Range(0.0, 1.0)) = 1.0
        _ContourColor ("Color", color) = (1,1,1,1)
        _ContourEmission ("Emission", Range(0.0, 1.0)) = 1.0

        // Radius Fading
        [Space(10)] [Header(Radius Fading)] [Space(5)]
        _Radius ("Fade Radius", Range(0.1,2.0)) = 1
        _RadiusFade ("Fade Radius Start", Range(0.1,1.0)) = 0.5 // Percentage Based
    }

    SubShader 
    { 
        // Depth only pass.
        Pass 
        {
            ZWrite On
            ColorMask 0
        }

        Tags { "RenderType"="Transparent" "Queue"="Transparent" "ForceNoShadowCasting" = "True" }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha:fade nofog  
        #pragma target 3.0

        struct Input 
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldPos;
        };

        sampler2D _MainTex;
        fixed4 _Color;
        
        // Contour Lines
        float _TerrainHeight, _TerrainOffsetX, _TerrainOffsetZ;
        int _ContourLayerSections;
        float _ContourLayerHeight, _ContourOffset, _ContourLineSize;
        fixed _ContourAlpha, _ContourSectionAlpha;
        fixed4 _ContourColor;

        // Radius Fading
        float _Radius, _RadiusFade;

        void surf (Input IN, inout SurfaceOutputStandard o) 
        {
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb * _Color;

            // Contour Lines
            if (_TerrainHeight != 0.0)
            {
                float4 objectOrigin = mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0));
                float singleLayer = _TerrainHeight / _ContourLayerHeight;// Relative layer height
                float sectionLayer = _TerrainHeight / (_ContourLayerHeight / _ContourLayerSections); 
                float contourLines = frac((objectOrigin.y - IN.worldPos.y + _ContourOffset) / singleLayer);
                float contourLayerFade = frac((objectOrigin.y - IN.worldPos.y + _ContourOffset) / sectionLayer) * _ContourLayerSections;
                contourLines = step(singleLayer * _ContourLineSize, contourLines);
                contourLines = saturate((1.0 - contourLines) - contourLayerFade) + (1.0 - contourLines) * 0.5 * _ContourSectionAlpha;
                o.Albedo += saturate((contourLines * _ContourColor) * _ContourAlpha);
                o.Emission = saturate((contourLines * _ContourColor) * _ContourAlpha);
                // Contour Lines Advance -> FXAA
            }

            // Radius Fading
            float4 radiusOrigin = mul(unity_ObjectToWorld, float4(_TerrainOffsetX, 0.0, _TerrainOffsetZ, 1.0));
            float pixelPos = distance(radiusOrigin.xyz, IN.worldPos);
            float proportionateFade = _Radius * _RadiusFade;
            float scaleFade = (pixelPos - proportionateFade) / (_Radius - proportionateFade); // Scaling arbitrary range to 0-1
            o.Alpha = 1.0;
            if (pixelPos > proportionateFade) o.Alpha = smoothstep(1.0, 0.0, clamp(scaleFade, 0.0, 1.0));
        }
        ENDCG
    }
    FallBack "Diffuse"
}