Shader "Unlit/chapter15-waterWave"
{
    Properties
    {
        _Color("Main Color",Color) = (0,0.15,0.115,1)  //水面颜色
        _MainTex ("Texture", 2D) = "white" {}        //水面波纹纹理
        _WaveMap("Wave map",2D) = "Bump"{}          //噪声生成的法线纹理
        _CubeMap("Environment Cubemap",Cube) = "_Skybox"{}  //反射的立方体纹理
        _WaveXSpeed("Wave Horizontal Speed",Range(-0.1,0.1)) = 0.01
        _WaveYSpeed("Wave Vertical Speed",Range(-0.1,0.1)) = 0.01
        _Distorition("Distortion",Range(0,100)) = 10          //模拟折射时图像的扭曲程度
    }
    
    SubShader
    {
        //修改队列的为透明 可以保证渲染该物体时 其他所有不透明物体已经被渲染
        Tags{"Queue" = "Transparent" "Rendertype" = "Opaque"}
        
        //抓取屏幕 并存入  refractiontex 纹理
        GrabPass
        {
            "_RefractionTex"
        }
        
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            sampler2D _MainTex,_WaveMap;
            float4 _MainTex_ST,_WaveMap_ST;
            fixed _WaveXSpeed,_WaveYSpeed;
            samplerCUBE _CubeMap;
            float _Distorition;

            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize; //纹素大小  为1/纹理分辨率
            
            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD1;
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0; //屏幕坐标

                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);

                o.uv.xy = TRANSFORM_TEX(v.vertex,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.vertex,_WaveMap);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               fixed3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);  //w存储的是世界坐标

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float2 speed=  _Time.y * float2(_WaveXSpeed,_WaveYSpeed);  //计算当前纹理便宜量

                //get the normal in tangent space
                //对法线采样并将法线还原到-1 1 取值之间
                fixed3 bump1 = UnpackNormal(tex2D(_WaveMap,i.uv.zw+speed)).rgb;
                fixed3 bump2 = UnpackNormal(tex2D(_WaveMap,i.uv.zw - speed)).rgb;
                fixed3 bump = normalize(bump1+bump2);   //两次结果相加并归一化获得切线空间下的法线向量
                //模拟折射效果
                float2 offset = bump.xy * _Distorition * _RefractionTex_TexelSize.xy;
                
                i.scrPos.xy = offset*i.scrPos.z + i.scrPos.xy; //offset*i.scrPos.z模拟深度越大折射越大的效果   也可以不乘 直接offset + i.scrPos.xy
                fixed3 refrCol = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;//透视除法 i.scrPos.xy/i.scrPos.w 在使用该坐标对屏幕图像进行采样获得 折射颜色

                //法线到世界空间
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
                fixed4 texColor = tex2D(_MainTex,i.uv.xy + speed); //主纹理颜色
                //反射方向
                fixed3 reflDir = reflect(-viewDir,bump);
                //反射颜色 =   根据反射方向对天空和进行采样 与 主纹理颜色   和    主颜色 相乘   获得反射颜色
                fixed3 feflCol = texCUBE(_CubeMap,reflDir).rgb * texColor.rgb * _Color.rgb;
                //菲涅尔数值
                fixed fresnel = pow(1-saturate(dot(viewDir,bump)),4);
                //根据菲涅尔系数  进行反射颜色和折射颜色混合
                fixed3 finalColor = feflCol * fresnel + refrCol *(1-fresnel);
                return fixed4(finalColor,1);
            }
            ENDCG
        }
    }
}
