//blinn-phone高光反射公式：specular = light颜色*specular颜色 * max（0，V · h)^gloss；
//gloss 是光泽度
//v是视角方向
//h是半角向量 = worldLight + viewDir  归一化


//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色

//在切线空间下计算光照模型
//在片元着色器通过纹理采样得到切线空间的法线，与切线空间的视角和光照方向进行计算。
//在顶点着色器中 吧视角方向和光照方向从模型空间变到切线空间  
//所以需要模型到切线的变换矩阵

Shader "UNITY SHADER BOOK/Chapter_7/NormalMapInTangentSpace"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _BumpMap("Normal Map",2D) = "bump"{}
        _BumpScale("Bump Scale",Range(-1,1)) = 0.0
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
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;  //存储模型的第一组纹理
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
            o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

            //计算binormal
            //unity内置宏  直接得到rotation
        	//unity   内置函数ObjSpaceLightDir 输入一个模型顶点坐标，得到模型空间中从该点到光源的光照方向。
        	//ObjSpaceViewDir	输入一个模型顶点坐标，得到模型空间中从该点到摄像机的观察方向。
            TANGENT_SPACE_ROTATION;
            
            o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;//rotation 表示从世界空间到切线空间的矩阵

            o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;//rotation 表示从世界空间到切线空间的矩阵
            
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            fixed3 tangentLightDir = normalize(i.lightDir); //切线空间下的光照方向
            fixed3 tangentViewDir = normalize(i.viewDir);//切线空间下的视角方向

            fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw); //对法线纹理进行采样
            fixed3 tangentNormal;
            //法线分量范围在-1 ，1     像素分量在0-1    所以在对法线纹理采样后 需要反映射  求得原本的法线方向
            tangentNormal = UnpackNormal(packedNormal); //映射回  法线
            tangentNormal.xy *= _BumpScale; //法相方向的xy 乘以_BumpScale 控制凹凸程度
            //法线都是单位矢量  所以z可以根据xy获得    1-（x*x + y*y） 开方
            tangentNormal.z = sqrt(1.0- saturate(dot(tangentNormal.xy,tangentNormal.xy)));

            fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb; //对纹理进行采样  返回纹素值    用采样结果和颜色相乘获得材质反射率

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; //获取环境光
            
            fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal,tangentLightDir)); //漫反射
            //别问  问就是公式
            fixed3 halfDir = normalize(tangentLightDir + tangentViewDir); 
            //_LightColor0内置光照变量     
            fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal,halfDir)),_Gloss);
            //相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
            //相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色
            fixed3 color = ambient + diffuse + specular;
            
            return fixed4(color,1.0);
        }
        ENDCG
        }
    }
    FallBack "Specular"
}
