Shader "DevirtualizationWithGeometry"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}                // Tekstura obiektu
        _MaskTex ("Mask for Dissolve", 2D) = "white" {}      // Maska obiektu
        _WireColor ("Wireframe Color", Color) = (1, 1, 1, 1) // Kolor siatki (domyślnie biały)
        _WireTint("Wire tint", Color) = (0.0, 0.7, 1.0, 1.0) // Kolor tła siatki
        _WireThickness ("Wireframe Thickness", Range(0, 1)) = 0.02  // Grubość linii siatki
        _Transition ("Transition", Range(0, 1)) = 0.0        // Zmienna kontrolująca przejście od tekstury do siatki
        _Feather ("Feather", Float) = 0.1                    // Rozmycie przejścia
        _DissolveColor ("Dissolve Color", Color) = (1.0, 0.5, 0.0, 1.0) // Kolor rozpuszczania
        _DissolveEmission ("Dissolve Emission", Float) = 20  // Emisja rozpuszczania
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"  "IgnoreProjector"="True"}
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha 
            Cull Off
            ZWrite On
            ZTest LEqual
            
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
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
                float3 normal : TEXCOORD3;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 bary : TEXCOORD1; // Współrzędne barycentryczne
            };

            sampler2D _MainTex;
            sampler2D _MaskTex;
            float4 _WireColor;
            float4 _DissolveColor;
            float4 _WireTint;
            float _WireThickness;
            float _Transition;
            float _Feather;
            float _DissolveEmission;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(mul((float3x3)unity_WorldToObject, v.vertex.xyz)); 
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2f IN[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;

                // Przypisanie pozycji i współrzędnych barycentrycznych
                o.pos = IN[0].vertex;
                o.uv = IN[0].uv;
                o.bary = float3(1.0, 0.0, 0.0); // Wierzchołek 1
                triStream.Append(o);

                o.pos = IN[1].vertex;
                o.uv = IN[1].uv;
                o.bary = float3(0.0, 1.0, 0.0); // Wierzchołek 2
                triStream.Append(o);

                o.pos = IN[2].vertex;
                o.uv = IN[2].uv;
                o.bary = float3(0.0, 0.0, 1.0); // Wierzchołek 3
                triStream.Append(o);
            }

            float4 frag(g2f i) : SV_Target
            {
                float4 texColor = tex2D(_MainTex, i.uv);
                float4 mask = tex2D(_MaskTex, i.uv);

                // Obliczenia dla siatki
                float wireMask = smoothstep(0.0, _WireThickness, i.bary.x) *
                                 smoothstep(0.0, _WireThickness, i.bary.y) *
                                 smoothstep(0.0, _WireThickness, i.bary.z);

                wireMask = 1.0 - wireMask; // Odwrócenie wartości, aby linie były widoczne

                // Dodanie wyostrzenia krawędzi siatki
                wireMask = smoothstep(0.0, 0.01, wireMask); // "Cienki" smoothstep dla ostrych krawędzi

                // Obliczanie ukrywania tekstury 
                float featherModifier = _Transition == 1 ? 0 : _Feather;
                float revealAmountTop = step(mask.r, _Transition + (1.0 / _Feather));
                float revealAmountTopTex = step(mask.r, _Transition + _Feather);
                float revealAmountBottom = step(mask.r, _Transition - featherModifier);
                float revealDifference = revealAmountTop - revealAmountBottom;

                // Kolor siatki (widoczny tylko w miejscach, gdzie tekstura zanika)
                float3 wireframeColor = lerp(_WireTint.rgb, _WireColor.rgb, wireMask);

                // Ustawienie przezroczystości - siatka powinna być widoczna, gdy tekstura zanika
                float3 finalColor = lerp(texColor.rgb, wireframeColor, revealDifference);
                float3 dissolveColor = lerp(0, _DissolveColor.rgb * _DissolveEmission , revealDifference);
                
                // Przezroczystość zależna od siatki
                float alpha = lerp(texColor.a, wireMask, revealDifference);

                // Dodanie minimalnej wartości alpha, aby uniknąć clipowania
                alpha = max(alpha, 0.3); // Zapewnienie minimalnej widoczności
                
                return float4(finalColor + dissolveColor * revealAmountTopTex, alpha);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
