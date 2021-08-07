Shader "Custom/Water"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _NormalTex("Normal Map",2D) = "bump"{}
        _NormalScale("Bump Scale",Range(-1,1)) = 0.0
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
        _offset("Offset",float) = 1
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
            #include "UnityCG.cginc"
        
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //必须使用  纹理名_ST 的方式声明纹理属性  S = scale  t = transform    xy存储的缩放 zw存储的偏移
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            float _NormalScale;
            fixed4 _Specular;
            float _offset;
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
            o.uv.zw = v.texcoord.xy * _NormalTex_ST.xy + _NormalTex_ST.zw;

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
            //别问  问就是公式  半角向量
            fixed3 halfDir = normalize(lightDir + viewDir); 
            
            fixed3 tangentNormal1 = UnpackNormal(tex2D(_NormalTex , i.uv  + _offset)).rgb;
            fixed3 tangentNormal2 = UnpackNormal(tex2D(_NormalTex , i.uv  - _offset)).rgb;
            fixed3 tangentNormal = normalize(tangentNormal1 + tangentNormal2);
            tangentNormal.xy *= _NormalScale;
            tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
            float3 worldNormal = normalize(half3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal), dot(i.TtoW2.xyz, tangentNormal)));

            float NdotH = max(0,dot(halfDir , worldNormal));  //BlinnPhong
            float NdotL = max(0,dot(worldNormal , lightDir)); // 漫反射

            //漫反射
            fixed3 diffuse = _LightColor0.rgb*_Color*saturate(dot(worldNormal , lightDir)) ;
            //高光
            fixed3 specular = pow( NdotH , _Specular * 128.0) * _Gloss;
            //环境光
            float3 ambient = _Color*UNITY_LIGHTMODEL_AMBIENT.xyz;
            
            return fixed4(diffuse + specular + ambient,1.0);
        }
        ENDCG
        }
    }
    FallBack "Specular"
}
