Shader "Custom/Devirtualization"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}                // Tekstura obiektu
        _MaskTex ("Mask for Dissolve", 2D) = "white" {}                // Maska obiektu
        _WireColor ("Wireframe Color", Color) = (1, 1, 1, 1) // Kolor siatki (domyślnie biały)
        _WireTint("Wire tint", Color) = (0.0, 0.7, 1.0, 1.0) // Kolor rozpuszczania (pomarańczowy)
        _WireThickness ("Wireframe Thickness", Range(0, 0.06)) = 0.02  // Grubość linii siatki
        _WireScale ("Wireframe Scale", Float) = 6.0        // Skalowanie siatki (rozmiar kwadratów)
        _Transition ("Transition", Range(0, 1)) = 0.0        // Zmienna kontrolująca przejście od tekstury do siatki
        _Feather ("Feather", Float) = 0.1
        _DissolveColor ("Dissolve Color", Color) = (1.0, 0.5, 0.0, 1.0) // Kolor rozpuszczania (pomarańczowy)
        _DissolveEmission ("Dissolve Emission", Float) = 20
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        Pass
        {
            Cull Off
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha // Zastosowanie blendowania dla przezroczystości
            Offset -1, -1

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float4 _WireColor;
            float4 _DissolveColor;
            float4 _WireTint;
            float _WireThickness;
            float _WireScale;
            float _Transition, _Feather;
            float _DissolveEmission;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Próbkowanie tekstury i maski
                float4 texColor = tex2D(_MainTex, i.uv.xy);
                float4 mask = tex2D(_MaskTex, i.uv.zw);

                // Scale Wireframe
                float2 scaledUV = i.uv * _WireScale;

                // Tworzenie siatki kwadratowej na bazie współrzędnych UV
                float2 gridUV = frac(scaledUV);
                float2 gridLine = smoothstep(0.0, _WireThickness, gridUV) * smoothstep(0.0, _WireThickness, 1.0 - gridUV);
                float wireMask = 1.0 - gridLine.x * gridLine.y;

                // Obliczanie ukrywania tekstury 
                float featerMod = _Transition == 1 ? 0 : 1.0 * _Feather;
                float revealAmountTop = step(mask.r, _Transition + (1 / _Feather));
                float revealAmountTopTex = step(mask.r, _Transition + _Feather);
                float revealAmountBottom = step(mask.r, _Transition - featerMod);
                float revealDifference = revealAmountTop - revealAmountBottom;

                // Kolor siatki (widoczny tylko w miejscach, gdzie tekstura znika)
                float3 wireframeColor = lerp(_WireTint.rgb , _WireColor.rgb, wireMask);

                // Ustawienie przezroczystości - siatka powinna być widoczna, gdy tekstura zanika
                float3 finalColor = lerp(texColor.rgb, wireframeColor, revealDifference);
                float3 dissolveCol = lerp(texColor.rgb / 2, _DissolveColor * _DissolveEmission, revealDifference);
                // Alpha set
                float gridTransparency = 1.0 - (revealAmountTop) * ( wireMask); // Transparent between lines
                float alpha = lerp(texColor.a, gridTransparency * revealDifference, revealDifference);
                
                return fixed4(finalColor.rgb + dissolveCol.rgb * revealAmountTopTex, alpha);
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}
