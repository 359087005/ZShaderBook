//blinn-phone高光反射公式：specular = light颜色*specular颜色 * max（0，V · h)^gloss；
//gloss 是光泽度
//v是视角方向
//h是半角向量 = worldLight + viewDir  归一化


//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色
Shader "UNITY SHADER BOOK/Chapter_7/SingleTexture"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
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

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //必须使用  纹理名_ST 的方式声明纹理属性  S = scale  t = transform    xy存储的缩放 zw存储的偏移
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;  //存储模型的第一组纹理
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.worldNormal = UnityObjectToWorldNormal(v.normal);

            o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

            o.uv = v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw; //在顶点着色器中，使用纹理属性值对纹理进行坐标变换
            //o.uv = TRANSFORM_TEX(V.texcoord,_Maintex);
            
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            fixed3 worldNormal = normalize(i.worldNormal); //法线向量
            
            fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos)); //光源向量

            fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb; //对纹理进行采样  返回纹素值    用采样结果和颜色相乘获得材质反射率

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; //获取环境光
            
            fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal,worldLight)); //漫反射
            //_WorldSpaceCameraPos 获得世界空间中的摄像机位置    减去顶点坐标就是 视角方向V
            fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
            //别问  问就是公式
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
