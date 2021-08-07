Shader "Custom/Chapter10-GlassRefraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}   
        _BumpMap("Normal map",2D) = "bump"{}
        _CubeMap("Env CubeMap",CUBE) = "_Skybox"{}
        _Distortion("Distortion",Range(0,100)) = 10 //控制模拟折射图像的扭曲程度
        _RefractAmount("Refract Amount",Range(0.0,1.0)) = 1 //控制折射程度  当他为0 只有反射 当他为1 只有折射
    }
    SubShader
    {
        //吧队列设置为透明 可以确保该物体渲染时 其他不透明物体已被渲染
        //渲染类型这是为了 在用着色器替换时 shader replacement 该物体可以在被需要时正确渲染
        Tags { "RenderType"="Opaque" "RenderQueue = Transparent"}

        GrabPass{"_RefractionTex"}  //该字符串名称 决定了 抓取到的屏幕图会被存在那个纹理
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _CubeMap;
            float _Distortion;
            fixed _RefractAmount;
            
            sampler2D _RefractionTex; //对应grabpass 的纹理
            float4 _RefractionTex_TexelSize; //纹理大小  纹理大小为256X512  则纹素大小为 (1/256 ,1/512)
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                float3 worldBionormal :TEXCOORD3;
            };

          v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);  //
                //内置函数  获得被抓取屏幕图像的采样坐标
                o.srcPos = ComputeGrabScreenPos(o.pos);

                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_Tex(v.texcoord,_BumpMap);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.nromal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBionormal = corss()

              
             
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               fixed3 worldNormal = normalize(i.worldNormal);
               fixed3 worldLightDir = normalize( UnityWorldSpaceLightDir(i.worldPos));
               fixed3 worldviewDir = normalize(i.worldViewDir);

               fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                 //autolight.cginc   计算光照衰减和阴影
                //第二个参数是v2f的结构体  使用SHADOW_ATTENUATION 来计算阴影值
                //第三个参数是世界空间坐标    计算光源空间下的坐标 在对照光照衰减纹理采样获得光照衰减
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                 //对立方体纹理采样需要使用CG函数 
                fixed3 reflection = texCUBE(_CubeMap,i.worldRefl).rgb ;

                //Schlick 菲涅耳近似等式：
                //FSchlick(v, n) = F0 + (1 - F0)(1 - dot(v, n))5
                //F0 就是反射系数 _FresnelScale  v是视角方向  n是表面法线
                fixed fresnel = _FresnelScale + (1-_FresnelScale) * pow(1-dot(worldviewDir,worldNormal),5);
                
                //"include lighting.cginc"
                fixed3 diff = _LightColor0.rgb * _Color.rgb * saturate(dot(worldNormal,worldLightDir));
               
                fixed3 color = ambient + lerp(diff,reflection,saturate(fresnel)) * atten;

                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    FallBack Off
}
