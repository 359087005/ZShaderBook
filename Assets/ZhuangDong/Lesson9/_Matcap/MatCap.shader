Shader "Unlit/MatCap"
{
    //nDir 法线贴图从切线空间到观察空间
    //取 RG 通道 remap到0-1 作为UV 采样 matcap图
    //叠加菲涅尔效果
    Properties
    {
        _MatCap ("Mat Cap", 2D) = "white" {}
        _NormalMap("Normal Map",2D) = "Bump"{}
        _FresnelPow("Fresnel Pow",float) = 1
        _MainIntersity("Intersity",float)= 1
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

            sampler2D _MatCap,_NormalMap;
            float4 _MatCap_ST,_NormalMap_ST;
            float _FresnelPow,_MainIntersity;

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
                float3 nDirVS = mul(UNITY_MATRIX_V, nDirWS);        // 计算MatcapUV
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz); // 计算Fresnel

                float2 matcapUV = nDirVS.rg * 0.5 + 0.5;
                float ndv = dot(nDirWS,vDirWS);

                fixed3 matcap =  tex2D(_MatCap,matcapUV);
                float fresnel = pow(saturate(1-ndv),_FresnelPow);
                fixed3 envSpecLighting = fresnel * matcap * _MainIntersity;
                
                return fixed4(envSpecLighting,1);
            }
            ENDCG
        }
    }
    fallback "Diffuse"
}
