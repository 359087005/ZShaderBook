// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

//blinn-phone高光反射公式：specular = light颜色*specular颜色 * max（0，V · h)^gloss；
//gloss 是光泽度
//v是视角方向
//h是半角向量 = worldLight + viewDir  归一化


//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色

//在世界空间下计算光照模型
//目的：在片元着色器吧法线方向从切线空间变换到世界空间
//要求：1，在顶点着色器中 计算切线空间到世界空间的变换矩阵 传递给片元着色器
//要求2，在片元着色器吧法线纹理中的法线方向从切线空间变换到世界空间

Shader "UNITY SHADER BOOK/Chapter_7/NormalMapInWorldSpace"
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
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };
        //计算变换矩阵
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
            o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

            float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//顶点坐标转换到世界空间下
            fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  //法线 模型到世界
            fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//切线 模型到世界
            fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w; //副法线   垂直于法线和切线的向量  v.tangent.w 判断方向

             o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
             o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
             o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
            return o;
        }
        //在世界空间下进行光照计算
        fixed4 frag(v2f i) : SV_Target
        {
            float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w); //获取世界坐标
            
            //在世界坐标系计算光源方向和视线朝向
            //UnityWorldSpaceLightDir //输入一个模型空间中的顶点位置，返回世界空间中从该点到光源的光照方向
            //UnityWorldSpaceViewDir //输入一个模型空间中的顶点位置，返回世界空间中从该顶点到摄像机的观察空间方向
            fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos)); 
            fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

            //法线分量范围在-1 ，1     像素分量在0-1    所以在对法线纹理采样后 需要反映射  求得原本的法线方向
            fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));//对法线纹理进行采样   然后映射回法线方向

            bump.xy*= _BumpScale;//法相方向的xy 乘以_BumpScale 控制凹凸程度
            //法线都是单位矢量  所以z可以根据xy获得    1-（x*x + y*y） 开方
            bump.z = sqrt(1.0- saturate(dot(bump.xy,bump.xy)));

            bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
            
            fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb; //对纹理进行采样  返回纹素值    用采样结果和颜色相乘获得材质反射率

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; //获取环境光
            
            fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump,lightDir)); //漫反射
            //别问  问就是公式
            fixed3 halfDir = normalize(lightDir + viewDir); 
            //_LightColor0内置光照变量     
            fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump,halfDir)),_Gloss);
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
