//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色

Shader "UNITY SHADER BOOK/Chapter_7/MaskTexture"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
    	_MainTex("Main Tex",2D) = "white"{}
    	_BumpMap("Normal Map",2D) = "bump"{} //bump默认是灰度图
    	_BumpScale("Bump Scale",float) = 1.0
    	_SpecularMask("Specular Mask",2D) = "white"{} //高光反射遮罩纹理
    	_SpecularScale("Specular Scale",float) = 1.0 //控制遮罩影响度的系数
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
			sampler2D _MainTex;   //
            float4 _MainTex_ST;   // 主纹理  法线纹理  遮罩纹理  均使用 纹理数形变量   所以修改朱文丽的平铺和偏移 会影响3个纹理采样
            sampler2D _BumpMap;
			float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
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
                float2 uv : TEXCOORD0;
            	float3 lightDir : TEXCOORD1;
            	float3 viewDir : TEXCOORD2;
            };
       
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex); //顶点坐标从模型到裁剪

			o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
			//unity内置宏  直接得到rotation
        	//unity   内置函数ObjSpaceLightDir 输入一个模型顶点坐标，得到模型空间中从该点到光源的光照方向。
        	//ObjSpaceViewDir	输入一个模型顶点坐标，得到模型空间中从该点到摄像机的观察方向。
        	TANGENT_SPACE_ROTATION;

        	o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;  //rotation 表示从世界空间到切线空间的矩阵

        	o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;	//rotation 表示从世界空间到切线空间的矩阵
        	
            return o;
        }
        //使用遮罩纹理的是片元着色器  用它控制模型表面的高光反射强度
        fixed4 frag(v2f i) : SV_Target
        {
			fixed3 tangentLightDir = normalize(i.lightDir);
        	fixed3 tangentViewDir = normalize(i.viewDir);
			//法线分量范围在-1 ，1     像素分量在0-1    所以在对法线纹理采样后 需要反映射  求得原本的法线方向
			fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv)); //对法线贴图进行采样 并还原
			tangentNormal.xy *= _BumpScale; //法相方向的xy 乘以_BumpScale 控制凹凸程度
            //法线都是单位矢量  所以z可以根据xy获得    1-（x*x + y*y） 开方
            tangentNormal.z = sqrt(1.0- saturate(dot(tangentNormal.xy,tangentNormal.xy)));
        	
			fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb; //对纹理进行采样  返回纹素值    用采样结果和颜色相乘获得材质反射率

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; //获取环境光
            //light颜色* Diffuse 颜色 *saturate(N · L)； 
            fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal,tangentLightDir)); //漫反射公式
            //别问  问就是公式
            fixed3 halfDir = normalize(tangentLightDir + tangentViewDir); 
            //对遮罩纹理进行采样  由于本书遮罩纹理每个纹素rbg分量一样，所以使用r计算掩码值，和高光系数相乘，控制高光反射强度.
            fixed specularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;
			//specular = light颜色*specular颜色 * max（0，V · h)^gloss；
        	fixed3 specular = _LightColor0.rbg * _Specular.rgb * pow(saturate(dot(tangentViewDir,halfDir)),_Gloss) * specularMask;

        	return fixed4(ambient + diffuse + specular, 1.0f);
        }
        ENDCG
        }
    }
    FallBack "Specular"
}
