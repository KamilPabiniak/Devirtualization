Shader "Devirtualization"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}                // Tekstura obiektu
        _MaskTex ("Mask for Dissolve", 2D) = "white" {}      // Maska obiektu
        _WireColor ("Wireframe Color", Color) = (1, 1, 1, 1) // Kolor siatki (domyślnie biały)
        _WireTint("Wire tint", Color) = (0.0, 0.7, 1.0, 1.0) // Kolor rozpuszczania
        _WireThickness ("Wireframe Thickness", Range(0.01, 0.3)) = 0.02  // Grubość linii siatki
        _WireScale ("Wireframe Scale", Float) = 6.0          // Skalowanie siatki (rozmiar kwadratów)
        _Transition ("Transition", Range(0, 1)) = 0.0        // Zmienna kontrolująca przejście od tekstury do siatki
        _Feather ("Feather", Float) = 0.1                    // Rozmycie przejścia
        _DissolveColor ("Dissolve Color", Color) = (1.0, 0.5, 0.0, 1.0) // Kolor rozpuszczania
        _DissolveEmission ("Dissolve Emission", Float) = 20  // Emisja rozpuszczania
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"  "IgnoreProjector"="True"}
        Cull Off
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha // Zastosowanie blendowania dla przezroczystości
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
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
            float _Transition;
            float _Feather;
            float _DissolveEmission;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Próbkowanie tekstury i maski
                float4 texColor = tex2D(_MainTex, i.uv);
                float4 mask = tex2D(_MaskTex, i.uv);

                // Skalowanie siatki
                float2 scaledUV = i.uv * _WireScale;

                // Tworzenie siatki kwadratowej na bazie współrzędnych UV
                float2 gridUV = frac(scaledUV);
                float gridLineX = smoothstep(0.0, _WireThickness, gridUV.x) * smoothstep(0.0, _WireThickness, 1.0 - gridUV.x);
                float gridLineY = smoothstep(0.0, _WireThickness, gridUV.y) * smoothstep(0.0, _WireThickness, 1.0 - gridUV.y);
                float wireMask = 1.0 - gridLineX * gridLineY;

                // Obliczanie ukrywania tekstury 
                float featherModifier = _Transition == 1 ? 0 : _Feather;
                float revealAmountTop = step(mask.r, _Transition + (1.0 / _Feather));
                float revealAmountTopTex = step(mask.r, _Transition + _Feather);
                float revealAmountBottom = step(mask.r, _Transition - featherModifier);
                float revealDifference = revealAmountTop - revealAmountBottom;

                // Kolor siatki (widoczny tylko w miejscach, gdzie tekstura zanika)
                //float3 wireframeColor =  _WireColor.rgb + wireMask;
                float3 wireframeColor =  lerp(_WireTint,_WireColor,wireMask);

                // Ustawienie przezroczystości - siatka powinna być widoczna, gdy tekstura zanika
                float3 finalColor = lerp(texColor.rgb, wireframeColor, revealDifference);
                float3 dissolveColor = lerp(texColor.rgb / 2, _DissolveColor * _DissolveEmission, revealDifference);
                
                // Alpha set
                float gridTransparency = _WireTint + wireMask;
                //wireMask ma wade. Nie możesz ustawić go by był transparent. Oszukaj to
                float alpha = lerp(texColor.a, gridTransparency, revealDifference);
                
                // Zapewnienie poprawnego renderowania przezroczystości z każdej strony
                //clip(alpha - 0.0993); // Zapobiega wyświetlaniu pikseli z alpha = 0
                UNITY_APPLY_FOG(i.fogCoord, texColor);
                return float4(finalColor + dissolveColor * revealAmountTopTex, alpha);
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}
