//高光反射公式：specular = light颜色*specular颜色 * max（0，V · r)^gloss；
//gloss 是光泽度
//v是视角方向
//r是反射方向  reflect（i，n）  入射方向i 法线N  返回反射方向

//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色

Shader "UNITY SHADER BOOK/Chapter_6/Specular Vertex Level"
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
                float3 color : COLOR;
            };
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);//顶点坐标转到裁剪空间
            //unity内置变量 环境光
            //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//获取环境光照

            fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject)); //法线转到世界
            //_WorldSpaceLightPos0 单个光源且是平行光获得光源方向 
            fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);//光源方向
            //_LightColor0内置光照变量  需引用Lighting.cginc
            fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));//漫反射颜色  

            fixed3 reflectDir = normalize(reflect(-worldLight,worldNormal));//获取反射
            //_WorldSpaceCameraPos 获得世界空间中的摄像机位置    减去顶点坐标就是 视角方向V
            fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);
            //_LightColor0内置光照变量  需引用Lighting.cginc  specular = light颜色*specular颜色 * max（0，V · r)^gloss；
            fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( saturate(dot(viewDir,reflectDir)),_Gloss);
            //相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
            //相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色
            o.color =  diffuse +  specular;

            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            return fixed4(i.color,1.0);
        }
        
        ENDCG
        }
    }
    FallBack "Diffuse"
}
