Shader "Unlit/BlinPhone"
{
    Properties
    {
        _MainColor("Main Color",Color) = (1,1,1,1)
        _Gloss("Gloss",float) = 30
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
            #include  "Lighting.cginc"

            fixed4 _MainColor;
            float _Gloss;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 pos : TEXCOORD1;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.pos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 nDir = normalize(i.worldNormal);
                fixed3 lDir = normalize(_WorldSpaceLightPos0);
                fixed3 vDir = normalize(_WorldSpaceCameraPos - i.pos);
                fixed3 hDir = normalize(lDir+vDir);
                
                fixed ndl = saturate(dot(nDir,lDir)) * 0.5 + 0.5;
                fixed rdv = pow(saturate(dot(hDir,nDir)),_Gloss);
                
                return ndl * _MainColor + rdv ;
            }
            ENDCG
        }
    }
}
