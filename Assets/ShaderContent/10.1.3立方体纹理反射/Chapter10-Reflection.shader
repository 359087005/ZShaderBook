Shader "Custom/Chapter10-Reflection"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _ReflectColor("Reflect Color",Color) = (1,1,1,1)
        _ReflectAmount("Reflect Amount",Range(0,1)) = 1
        _CubeMap("Reflect CubeMap",CUBE) = "_Skybox"{}
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
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            struct a2v
            {
                float4 vertex : POSITION;
                float3 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefl :TEXCOORD3;
            };

            fixed4 _Color;
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
            samplerCUBE _CubeMap;
            
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos); //输入世界空间顶点坐标  返回世界空间从该点到摄像机的方向
                o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);  //l  n    光方向可以由光路可逆获得
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               fixed3 worldNormal = normalize(i.worldNormal);
               fixed3 worldLightDir = normalize( UnityWorldSpaceLightDir(i.worldPos));
               fixed3 worldviewDir = normalize(i.worldViewDir);

               fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //"include lighting.cginc"
                fixed3 diff = _LightColor0.rgb * _Color.rgb * saturate(dot(worldNormal,worldLightDir));
               //对立方体纹理采样需要使用CG函数 
                fixed3 reflection = texCUBE(_CubeMap,i.worldRefl).rgb * _ReflectColor.rgb;
                //autolight.cginc   计算光照衰减和阴影
                //第二个参数是v2f的结构体  使用SHADOW_ATTENUATION 来计算阴影值
                //第三个参数是世界空间坐标    计算光源空间下的坐标 在对照光照衰减纹理采样获得光照衰减
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                //环境光 +       _ReflectAmount混合漫反射和反射颜色 
                fixed3 color = ambient + lerp(diff,reflection,_ReflectAmount) * atten;

                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    FallBack Off
}
