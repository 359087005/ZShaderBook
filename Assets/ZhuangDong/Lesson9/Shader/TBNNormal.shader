Shader "Unlit/TBNNormal"
{
    Properties
    {
        _NormalTexture ("Normal Texture", 2D) = "bump" {}
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
                float4 tangent:TANGENT;
                float4 normal:NORMAL;
                
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 worldTangent : TEXCOORD1;
                float4 worldNormal : TEXCOORD2;
                float4 worldBiNormal : TEXCOORD3;
            };

            sampler2D _NormalTexture;
            float4 _NormalTexture_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldNormal.xyz = UnityObjectToWorldNormal(v.normal);
                o.worldTangent.xyz = normalize(mul(unity_ObjectToWorld,v.tangent));
                o.worldBiNormal.xyz = normalize(cross(o.worldNormal,o.worldTangent) * v.tangent.w);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normalMap = UnpackNormal(tex2D(_NormalTexture,i.uv));
                float3x3 tbn = float3x3(i.worldTangent.xyz,i.worldBiNormal.xyz,i.worldNormal.xyz);
                float3 nDir =normalize(mul(normalMap,tbn));               

                float3 l = _WorldSpaceLightPos0;
                float ndl = saturate(dot(nDir,l));
                return fixed4(ndl,ndl,ndl,1);
            }
            ENDCG
        }
    }
}
