Shader "Devirtualization"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}                
        _MaskTex ("Mask for Dissolve", 2D) = "white" {}      
        _Transition ("Transition", Range(0, 1)) = 0.0      
        _WireColor ("Wireframe Color", Color) = (1, 1, 1, 1) // Grid color - lines
        _WireTint("Wire Tint", Color) = (0.0, 0.7, 1.0, 1.0) // Grid color - background
        _DissolveColor ("Dissolve Color", Color) = (1.0, 0.5, 0.0, 1.0) 
        _DissolveEmission ("Dissolve Emission", Float) = 20  
        _WireThickness ("Wireframe Thickness", Range(0, 1)) = 0.02  
        _Feather ("Feather", Range(0, 0.01)) = 0.008     
        [Toggle]             
        _ShowWireframe ("Show Wireframe", Float) = 1.0
        
        _ShowWireTint ("Show Wire Tint", Float) = 0.3
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"  
            "IgnoreProjector"="True"  
            "LightMode" = "SRPDefaultUnlit"
        }
        Stencil 
        {
            Ref 0
            Pass Invert
            Fail IncrSat
        }
        LOD 100

        Pass // Back of the object
        {
            Blend SrcAlpha OneMinusSrcAlpha 
            Cull Front 
            ZTest LEqual
            ZWrite On
            
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
                float3 bary : TEXCOORD1; 
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
            float _ShowWireframe;
            float _ShowWireTint;

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
                o.pos = IN[0].vertex;
                o.uv = IN[0].uv;
                o.bary = float3(1.0, 0.0, 0.0); // vertex 1
                triStream.Append(o);

                o.pos = IN[1].vertex;
                o.uv = IN[1].uv;
                o.bary = float3(0.0, 1.0, 0.0); //  2
                triStream.Append(o);

                o.pos = IN[2].vertex;
                o.uv = IN[2].uv;
                o.bary = float3(0.0, 0.0, 1.0); // 3
                triStream.Append(o);
            }

            float4 frag(g2f i) : SV_Target
            {
                float4 texColor = tex2D(_MainTex, i.uv);
                float4 mask = tex2D(_MaskTex, i.uv);
                
                float wireMask = smoothstep(0.0, _WireThickness, i.bary.x) *
                                 smoothstep(0.0, _WireThickness, i.bary.y) *
                                 smoothstep(0.0, _WireThickness, i.bary.z);

                wireMask = 1.0 - wireMask; 
                
                wireMask = smoothstep(0.0, 0.01, wireMask); // For better lines

                wireMask *= _ShowWireframe; // Toggle wireframe visibility
                
                float feather_modifier_full = _Transition == 1 ? 0 : _Feather;
                float feather_modifier_zero = _Transition == 0 ? 0 : _Feather;
                float revealAmountTop = step(mask.r, _Transition + (1.0 / _Feather));
                float revealAmountTopTex = step(mask.r, _Transition + feather_modifier_zero);
                float revealAmountBottom = step(mask.r, _Transition - feather_modifier_full);
                float revealDifference = revealAmountTop - revealAmountBottom;

                float3 wireframeColor = lerp(_WireTint.rgb, _WireColor.rgb, wireMask);
                wireframeColor *= _ShowWireTint; // Toggle wire tint visibility

                float3 finalColor = lerp(texColor.rgb, wireframeColor, revealDifference);
                float3 dissolveColor = lerp(0, _DissolveColor.rgb * _DissolveEmission , revealDifference);
                
                float alpha = lerp(texColor.a, wireMask, revealDifference);
                
                alpha = max(alpha, _ShowWireTint); // Transparency
                
                return float4(finalColor + dissolveColor * revealAmountTopTex, alpha);
            }
            ENDCG
        }

        Pass // Front of the object
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Stencil
            {
                Ref 1
                Comp Less
            }
            Blend SrcAlpha OneMinusSrcAlpha 
            Cull Back 
            ZTest LEqual
            ZWrite On

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
                float3 bary : TEXCOORD1; 
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
            float _ShowWireframe;
            float _ShowWireTint;

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
                
                o.pos = IN[0].vertex;
                o.uv = IN[0].uv;
                o.bary = float3(1.0, 0.0, 0.0); // 1
                triStream.Append(o);

                o.pos = IN[1].vertex;
                o.uv = IN[1].uv;
                o.bary = float3(0.0, 1.0, 0.0); // 2
                triStream.Append(o);

                o.pos = IN[2].vertex;
                o.uv = IN[2].uv;
                o.bary = float3(0.0, 0.0, 1.0); // 3
                triStream.Append(o);
            }

            float4 frag(g2f i) : SV_Target
            {
                float4 texColor = tex2D(_MainTex, i.uv);
                float4 mask = tex2D(_MaskTex, i.uv);

                float wireMask = smoothstep(0.0, _WireThickness, i.bary.x) *
                                 smoothstep(0.0, _WireThickness, i.bary.y) *
                                 smoothstep(0.0, _WireThickness, i.bary.z);

                wireMask = 1.0 - wireMask;
                
                wireMask = smoothstep(0.0, 0.01, wireMask);

                wireMask *= _ShowWireframe; // Toggle wireframe visibility
                
                float featherModifier = _Transition == 1 ? 0 : _Feather;
                float feather_modifier_zero = _Transition == 0 ? 0 : _Feather;
                float revealAmountTop = step(mask.r, _Transition + (1.0 / _Feather));
                float revealAmountTopTex = step(mask.r, _Transition + feather_modifier_zero);
                float revealAmountBottom = step(mask.r, _Transition - featherModifier);
                float revealDifference = revealAmountTop - revealAmountBottom;

                float3 wireframeColor = lerp(_WireTint.rgb, _WireColor.rgb * 4, wireMask);
                wireframeColor *= _ShowWireTint; // Toggle wire tint visibility

                float3 finalColor = lerp(texColor.rgb, wireframeColor, revealDifference);
                float3 dissolveColor = lerp(0, _DissolveColor.rgb * _DissolveEmission , revealDifference);
                
                float alpha = lerp(texColor.a, wireMask, revealDifference);
                
                alpha = max(alpha, _ShowWireTint);
                
                return float4(finalColor + dissolveColor * revealAmountTopTex, alpha);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
