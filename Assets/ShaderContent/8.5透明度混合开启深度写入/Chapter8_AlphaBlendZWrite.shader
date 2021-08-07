//相乘 光乘物体本身的属性 比如环境光乘以物体的albedo  就是我们看到的物体反射的环境光
//相加 当物体被多个光源照射时   把物体反射这些光源颜色相加 就是最终颜色

Shader "UNITY SHADER BOOK/Chapter_8/AlphaBlend ZWrite"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
    	_MainTex("Main Tex",2D) = "white"{}
    	_AlphaScale("Alpha Scale",Range(0,1)) = 0.5
    }
    SubShader
    {
            //渲染队列为透明  不受投影器影响    渲染类型设置为transparent组
       Tags  {"Queue" = "Transparent" "IgnoreProjector" = "true" "RenderType" = "Transparent"}

       Pass  //该pass为了吧模型深度信息写入到深度缓冲中  colormask用于设置颜色通道的写掩码   
        {
            ZWrite On
            ColorMask 0   //ColorMask RGB   A    0      其他任何RGBA的组合   当为0时  该PASS 不写入任何颜色通道 不会输出任何颜色
        }
		
       Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            ZWrite Off          
            Blend SrcAlpha OneMinusSrcAlpha   //源颜色(该片元的颜色)的混合因子设为srcalpha 目标颜色（已存在于颜色缓冲中的颜色）的混合因子设置为OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
			sampler2D _MainTex;   //
            float4 _MainTex_ST;   // 主纹理  法线纹理  遮罩纹理  均使用 纹理数形变量   所以修改朱文丽的平铺和偏移 会影响3个纹理采样
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;  //存储模型的第一组纹理
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };
       
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex); //顶点坐标从模型到裁剪
            o.worldNormal = UnityObjectToWorldNormal(v.normal); //把模型空间下的法线向量转换到世界空间
            o.worldPos =mul( unity_ObjectToWorld,v.vertex).xyz;   //模型空间转世界空间

            //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的。
            // 两个函数等价
            //o.uv =   TRANSFORM_TEX(v.texcoord,_MainTex);
            //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
            o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
        	
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            fixed3 worldNormal = normalize(i.worldNormal);
            //输入一个模型空间中的顶点位置，返回世界空间中从该点到光源的光照方向
            fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

            fixed4 texColor = tex2D(_MainTex, i.uv);//采样贴图
        	
            //clip(texColor.a - _AlphaScale);

			fixed3 albedo = texColor.rgb * _Color.rgb; 

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; //获取环境光
            //light颜色* Diffuse 颜色 *saturate(N · L)； 
            fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir)); //漫反射公式

            return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
        }
        ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
