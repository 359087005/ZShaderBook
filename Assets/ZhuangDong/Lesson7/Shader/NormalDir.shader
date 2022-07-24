Shader "Unlit/NormalDir"
{
    Properties
    {
        _UpColor("Up Color",Color) = (1,1,1,1)
        _DownColor("Down Color",Color) = (1,1,1,1)
        _MiddleColor("Middle Color",Color) = (1,1,1,1)
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

            fixed4 _UpColor,_DownColor,_MiddleColor;
            
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
                fixed up = saturate(nDir.g);
                fixed down = saturate(nDir.g * -1);
                fixed middle = 1-up-down;

                fixed3 upcolor =up *  _UpColor;
                fixed3 downcolor =down *  _DownColor;
                fixed3 middlecolor =middle *  _MiddleColor;
                
                fixed3 result = upcolor + downcolor + middlecolor;
                
                return fixed4(result,1);
            }
            ENDCG
        }
    }
}
