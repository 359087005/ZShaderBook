//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色

Shader "UNITY SHADER BOOK/Chapter_7/RampTexture"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
       _RampTex("Ramp Tex",2D) = "white"{}
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
            sampler2D _RampTex;
            float4 _RampTex_ST;  //纹理属性变量  格式固定
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
            
           o.worldNormal = UnityObjectToWorldNormal(v.normal); //法线 模型到世界

            o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//顶点 模型到世界

            o.uv = TRANSFORM_TEX(v.texcoord,_RampTex);//将模型顶点的uv和Tiling、Offset两个变量进行运算，计算出实际显示用的定点uv
            
            return o;
        }
        //在世界空间下进行光照计算
        fixed4 frag(v2f i) : SV_Target
        {
			fixed3 worldNormal = normalize(i.worldNormal);
			//得到世界空间中从  参数  到光源（_WorldSpaceLightPos0）的光照方向。
			fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
			//环境光         //环境光 系统内置 需要引用Lighting.cginc    
			fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz;
			//半兰伯特光照公式 0.5 *（N · L） +0.5   映射到0-1之间
			fixed halfLambert = 0.5 * dot(worldNormal,worldLightDir) + 0.5;
        	//fixed halfLambert =dot(worldNormal,worldLightDir);
			//构建一个纹理坐标 并对渐变纹理进行采样(渐变纹理是一个一维纹理，因此UV方向都使用halfLambert)   渐变纹理颜色x材质颜色  获得最终漫反射颜色
			fixed3 diffuseColor = tex2D(_RampTex,fixed2(halfLambert,halfLambert)).rgb * _Color.rgb;
			//fixed3 diffuseColor = tex2D(_RampTex,i.uv).rgb * _Color.rgb;
			//_LightColor0  前向渲染   光源颜色  内置函数
			fixed3 diffuse = _LightColor0.rgb * diffuseColor;			
			//UnityWorldSpaceViewDir   通过世界坐标系下的点   获得该点到摄像机的观察方向
			fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
			//半角向量			
			fixed3 halfDir = normalize(worldLightDir + viewDir);
			//blinn-phone光照公式
			fixed3 specular = _LightColor0.rgb *_Specular.rgb * pow(saturate(dot(viewDir,halfDir)),_Gloss);
			//颜色相加
        	//return fixed4(diffuseColor + specular + ambient ,1.0);
            return fixed4(halfLambert,halfLambert,halfLambert ,1.0);
        }
        ENDCG
        }
    }
    FallBack "Specular"
}
