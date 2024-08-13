Shader "Custom/ColoredWireframeOnTransparent3D"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}                // Tekstura obiektu
        _MaskTex ("Mask for Dissolve", 2D) = "white" {}                // Maska obiektu
        _WireColor ("Wireframe Color", Color) = (1, 1, 1, 1) // Kolor siatki (domyślnie biały)
        _WireThickness ("Wireframe Thickness", Range(0.01, 0.06)) = 0.02  // Grubość linii siatki
        _WireScale ("Wireframe Scale", Float) = 6.0        // Skalowanie siatki (rozmiar kwadratów)
        _Transition ("Transition", Range(0, 1)) = 0.0        // Zmienna kontrolująca przejście od tekstury do siatki
        _Feather ("Feather", Float) = 0
        _DissolveColor ("Dissolve Color", Color) = (1.0, 0.5, 0.0, 1.0) // Kolor rozpuszczania (pomarańczowy)
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" }
        LOD 200

        // Rysowanie zarówno z przodu jak i z tyłu obiektu
        Pass
        {
            Cull Off
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha

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
            float _WireThickness;
            float _WireScale;
            float _Transition, _Feather;

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

                // Skalowanie siatki
                float2 scaledUV = i.uv * _WireScale;

                // Tworzenie siatki kwadratowej na bazie współrzędnych UV
                float2 gridUV = frac(scaledUV);
                float2 gridLine = smoothstep(0.0, _WireThickness, gridUV) * smoothstep(0.0, _WireThickness, 1.0 - gridUV);
                float wireMask = 1.0 - gridLine.x * gridLine.y;

                // Obliczanie wartości revealAmount
                float revealAmountTop = step(mask.r, _Transition - _Feather);
                float revealAmountBottom = step(mask.r, _Transition + _Feather);
                float revealDifference = revealAmountTop - revealAmountBottom;

                // Określanie momentu, gdy tekstura znika i pojawia się siatka
                float wireTransition = saturate((_Transition) / _Feather);

                // Mieszanie koloru siatki z teksturą, gdy tekstura zanika
                float3 finalColor = lerp(texColor.rgb, _DissolveColor, revealDifference);
                finalColor = lerp(finalColor.rgb, _WireColor.rgb, wireTransition * wireMask);

                // Ustawienie przezroczystości - siatka powinna być widoczna, gdy tekstura zanika
                float alpha = texColor.a * (1.0 - wireTransition) + wireTransition * wireMask;
                fixed4 fin = fixed4(finalColor.rgb, alpha);

                return fin;
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}
