//兰伯特光照公式:diffuse = light颜色* Diffuse 颜色 *saturate(N · L)；        dot(n,l)


//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色
Shader "UNITY SHADER BOOK/Chapter_6/Diffuse Pixed Level"
{
    Properties
    {
       _Diffuse("Diffuse",Color) = (1,1,1,1)
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

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
            };
        v2f vert(a2v v)
        {
            v2f o;
            //模型顶点转换到裁剪空间
            o.pos = UnityObjectToClipPos(v.vertex);
            //法线转换到世界空间
            o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);

            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            //环境光 系统内置 需要引用Lighting.cginc
            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
    
            fixed3 worldNormal = normalize(i.worldNormal);
            //当场景只存在一个平行光源时   可以该内置属性  光源方向
            fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
            //兰伯特公式
            fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));

            fixed3 color = ambient+diffuse;
            
            return fixed4(color,1.0);

          
        }
        
        ENDCG
        }
    }
    FallBack "Diffuse"
}
