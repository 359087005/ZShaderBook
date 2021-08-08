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
        Tags { "RenderType"="Opaque" "Queue" ="Transparent"}

        GrabPass{"_RefractionTex"}  //该字符串名称 决定了 抓取到的屏幕图会被存在那个纹理
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

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
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
				float4 scrPos : TEXCOORD4;
            };

          v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);  //
                //内置函数  获得被抓取屏幕图像的采样坐标
                o.scrPos = ComputeGrabScreenPos(o.pos);
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);
              //在片元着色器中把法线方向从切向空间变换到世界空间下     计算顶点对应的从切线空间到世界空间的变换矩阵
             
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;
             //xyz  顶点切线  副切线  法线      第四个值 利用起来 存储世界空间下的顶点坐标
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //通过ttow0 w 分量得到世界坐标
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                //通过该值获得对应的视角方向
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                //对法线纹理采样得到 切线空间下的法线方向
                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                //使用bump值和_Distortion   _RefractionTex_TexelSize 对屏幕图像采样坐标进行偏移  模拟折射效果
                
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.scrPos.xy = offset + i.scrPos.xy;
            	fixed3 refrCol =tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;
                
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 reflCol = texCUBE(_CubeMap, reflDir).rgb * texColor.rgb;
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
				return fixed4(finalColor, 1);
            }
            ENDCG
        }
    }
    FallBack Off
}
