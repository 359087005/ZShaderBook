Shader "Unlit/Fresnel"
{
    Properties
    {
        _Power("Fresnel Power",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
            };

            float _Power;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 n = normalize(i.normal);
                fixed3 v = normalize(_WorldSpaceCameraPos - i.worldPos);
                fixed ndv  = saturate(dot(n,v));
                fixed fresnel = pow(1-ndv,_Power);
                
                return fresnel;
            }
            ENDCG
        }
    }
}
