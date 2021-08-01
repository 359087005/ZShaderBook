//blinn-phone高光反射公式：specular = light颜色*specular颜色 * max（0，V · h)^gloss；
//gloss 是光泽度
//v是视角方向
//h是半角向量 = worldLight + viewDir  归一化


//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色
Shader "UNITY SHADER BOOK/Chapter_6/BlinnPhoneUseBuildInFunctionMat"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
       Pass
        {
            Tags {"LightMode" = "ForwardBase"}
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.worldNormal = UnityObjectToWorldNormal(v.normal);

            o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
            
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; //获取环境光
    
            fixed3 worldNormal = normalize(i.worldNormal); //法线向量
            
            fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos)); //光源向量

            fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight)); //漫反射
              //_WorldSpaceCameraPos 获得世界空间中的摄像机位置    减去顶点坐标就是 视角方向V
            fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

            fixed3 halfDir = normalize(worldLight + viewDir); 
            //_LightColor0内置光照变量     高光反射公式specular = light颜色*specular颜色 * max（0，V · r)^gloss；
            fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldLight,halfDir)),_Gloss);
            //相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
            //相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色
            fixed3 color = ambient+diffuse + specular;
            
            return fixed4(color,1.0);
        }
        ENDCG
        }
    }
    FallBack "Diffuse"
}
