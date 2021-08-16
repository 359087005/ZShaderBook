Shader "Unlit/Chapter15-Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} //物体圆满的漫反射
        _BurnAmount("Burn Amount",Range(0,1)) = 0.0 //消融程度  0是正常 1是全消
        _LineWidth("Burn Line Width",Range(0,0.2)) = 0.1 //模拟烧焦的线宽
        _BumpMap("Normal Map",2D) = "bump"{} //物体的法线纹理
        _BurnFirstColor("Brun First Color",Color) = (1,0,0,1) //火焰边缘的2中颜色
        _BurnSecondColor("Brun Second Color",Color) = (1,0,0,1)
        _BurnMap("Burn Map",2D) =  "White"{} //噪声纹理
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CULL Off //得双面剔除  消融会导致露出模型内部结构
            CGPROGRAM
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            #pragma  multi_compile_fwdbase  // 叠加

            sampler2D _MainTex,_BumpMap,_BurnMap;
            float4 _MainTex_ST,_BumpMap_ST,_BurnMap_ST;
            fixed4 _BurnFirstColor,_BurnSecondColor;
            fixed _BurnAmount,_LineWidth;
            
            #pragma vertex vert
            #pragma fragment frag
            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0; //texcoord = uv
                float3 normal :NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uvMainTex : TEXCOORD0;
                float2 uvBumpMap : TEXCOORD1;
                float2 uvBurnMap : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);


                 //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的。
            // 两个函数等价
            //o.uv =   TRANSFORM_TEX(v.texcoord,_MainTex);
            //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uvMainTex = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord,_BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord,_BurnMap);
            //计算binormal
            //unity内置宏  直接得到rotation
        	//unity   内置函数ObjSpaceLightDir 输入一个模型顶点坐标，得到模型空间中从该点到光源的光照方向。
        	//ObjSpaceViewDir	输入一个模型顶点坐标，得到模型空间中从该点到摄像机的观察方向。
                TANGENT_SPACE_ROTATION; //变换到切线空间矩阵
                
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;//获表示从世界空间到切线空间的矩阵
                
                o.worldPos = mul( unity_ObjectToWorld,(v.vertex)).xyz;

                TRANSFER_SHADOW(o)
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 burn = tex2D(_BurnMap,i.uvBurnMap).xyz; //对噪声纹理采样  当小于0时  剔除像素 不显示到屏幕上

                clip(burn.r - _BurnAmount); //取得小数部分

                float3 tangenLightDir = normalize(i.lightDir);
                 //法线分量范围在-1 ，1     像素分量在0-1    所以在对法线纹理采样后 需要反映射  求得原本的法线方向
                fixed3 tangetNormal = UnpackNormal(tex2D(_BumpMap,i.uvBumpMap));
                //根据漫反射纹理获得材质反射率albedo
                fixed3 albedo = tex2D(_MainTex,i.uvMainTex).xyz;
                //计算环境光
                fixed3 ambition = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; //内置环境光定义  
                //计算漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangetNormal,tangenLightDir));                
                //求  少交的颜色  在linewidth内模拟一个烧焦颜色变化
                fixed t = 1- smoothstep(0.0,_LineWidth,burn.r-_BurnAmount); //根据值返还0-1的数
                fixed3 burnColor = lerp(_BurnFirstColor,_BurnSecondColor,t);
                burnColor = pow(burnColor,5);

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                //正常光照颜色(环境光+漫反射)                           烧焦颜色      当burnamount为0时不显示消融效果
                fixed3 finalColor = lerp(ambition + diffuse * atten,burnColor,t * step(0.0001,_BurnAmount));  //既是当b>=a时返回1，否则返回0


                return fixed4(finalColor,1);
                
                
            }
            ENDCG
        }
        
        Pass
        {
            Tags{"LightMode" = "ShadowCaster"} //用于投射阴影期的pass 需要被设置为shadercaster   还需要使用指令multi_compile_shadowcaster
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma  multi_compile_shadowcaster 
            #include "UnityCG.cginc"

            sampler2D _BurnMap;
            float4 _BurnMap_ST;
            fixed _burnAmount;
            
            struct  v2f
            {
                V2F_SHADOW_CASTER;  //定义阴影投射需要定义的变量
                float uvBurnMap : TEXCOORD1;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o) //unity帮助完成

             //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的。
            // 两个函数等价
            //o.uv =   TRANSFORM_TEX(v.texcoord,_MainTex);
            //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord,_BurnMap); //

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 burn = tex2D(_BurnMap,i.uvBurnMap).rgb; //使用噪声纹理进行采样
                clip(burn.r-_burnAmount);  //剔除片元
                SHADOW_CASTER_FRAGMENT(i)//把结果输出到深度图和阴影映射纹理中
            }
            ENDCG
        }
    }
}
