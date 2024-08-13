Shader "Custom/ColoredWireframeOnTransparent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}                // Tekstura obiektu
        _MaskTex ("Mask for Dissolve", 2D) = "white" {}                // Maska obiektu
        _WireColor ("Wireframe Color", Color) = (1, 1, 1, 1) // Kolor siatki (domyślnie biały)
        _WireThickness ("Wireframe Thickness", Float) = 0.02  // Grubość linii siatki
        _WireScale ("Wireframe Scale", Float) = 6.0        // Skalowanie siatki (rozmiar kwadratów)
        [Emum(UnityEngine.Rendering.BlendMode)]
        _Transition ("Transition", Range(0, 1)) = 0.0        // Zmienna kontrolująca przejście od tekstury do siatki
        _Feather ("Feather", Float) = 0
        _DissolveColor ("Dissolve Color", Color) = (1.0, 0.5, 0.0, 1.0) // Kolor rozpuszczania (pomarańczowy)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" }
        LOD 200
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha 
        BlendOp [_Opp]

        Pass
        {
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Próbkowanie tekstury
                float4 texColor = tex2D(_MainTex, i.uv.xy);
                float4 mask = tex2D(_MaskTex, i.uv.zw);

                // Skalowanie siatki
                float2 scaledUV = i.uv * _WireScale;

                // Tworzenie siatki kwadratowej na bazie współrzędnych UV
                float2 gridUV = frac(scaledUV);
                float2 gridLine = smoothstep(0.0, _WireThickness, gridUV) * smoothstep(0.0, _WireThickness, 1.0 - gridUV);
                float wireMask = gridLine.x * gridLine.y;
                float4 wireColor = float4(_WireColor.rgb, 1.0);
                
                
                float4 maskAdd = float4(texColor.rgb, texColor.a * mask.r);
                //float dissolveAmmount = smoothstep(mask.r -_Feather, mask.r + _Feather,_Transition);
                float revealAmountTop = step(mask.r, _Transition + _Feather);
                float revealAmountBottom = step(mask.r, _Transition - _Feather);
                float revealDifference = revealAmountTop - revealAmountBottom;

                // Połączenie efektu z teksturą i kolorem siatki
                //float4 finalColor = fixed4(revealDifference.xxx,  1); //wireColor,
                float3 finalColor = lerp(texColor.rgb, _DissolveColor, revealDifference); //wireColor,
                // Siatka widoczna tylko przy pełnym przejściu
                fixed4 fin = fixed4(finalColor.rgb, texColor.a * revealAmountTop);
                fin.a *= wireMask * _Transition + (1.0 - _Transition); 
                return fin;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
