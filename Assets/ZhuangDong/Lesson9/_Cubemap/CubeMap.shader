Shader "Unlit/CubeMap"
{
    Properties
    {
        _Cubemap ("Cube Cap", Cube) = "white" {}
        _NormalMap("Normal Map",2D) = "Bump"{}
        _CubemapMip("CubeMapMipLevel",Range(0,7)) = 0
        _FresnelPow("Fresnel Pow",Range(0,10)) = 1
        _MainIntersity("Intersity",Range(0,5))= 1
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
                float4 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 tDirWS:TEXCOORD1;
                float3 bDirWS:TEXCOORD2;
                float3 nDirWS:TEXCOORD3;
                float3 posWS :TEXCOORD4;
            };

            samplerCUBE _Cubemap;
            sampler2D _NormalMap;
            float4 _CubeCap_ST,_NormalMap_ST;
            float _FresnelPow,_MainIntersity,_CubemapMip;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex);

                //这里必须用切线的xyz  不能直接用切线
                o.tDirWS = normalize(mul(unity_ObjectToWorld,v.tangent.xyz));
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                //这里叉乘必须是先法线后切线
                o.bDirWS = normalize(cross(o.nDirWS,o.tDirWS) * v.tangent.w);
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float3 nDirTS = UnpackNormal(tex2D(_NormalMap, i.uv)).rgb;
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 nDirWS = normalize(mul(nDirTS, TBN));        // 计算nDirVS 计算Fresnel
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz); // 计算Fresnel

                float3 vrDirWS =  reflect(-vDirWS,nDirWS);
                
                float ndv = dot(nDirWS,vDirWS);

               float3 var_Cubemap = texCUBElod(_Cubemap, float4(vrDirWS, _CubemapMip)).rgb;
                float fresnel = pow(max(0.0, 1.0 - ndv), _FresnelPow);
                float3 envSpecLighting = var_Cubemap * fresnel * _MainIntersity;

                
                return fixed4(envSpecLighting,1);
            }
            ENDCG
        }
    }
    fallback "Diffuse"
}
