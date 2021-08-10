Shader "Unlit/Chapter13-MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("Blur Size",float) = 1
    }
    SubShader
    {
            CGINCLUDE
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;  //纹素值大小   对深度纹理 采样坐标进行平台差异化处理
            sampler2D _CameraDepthTexture;  //unity 传递给我们的深度纹理
            float4x4 _CurrentViewProjectionInverseMatrix; //脚本传递的矩阵
            float4x4 _PreviousViewProjectionMatrix; //脚本传递的矩阵
            half _BlurSize;
            
            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                half2 uv_depth : TEXCOORD1;
            };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.uv_depth = v.texcoord;

                 //纹理坐标差异化处理     DX平台 开启抗锯齿处理多张渲染图像   图像在竖直方向的朝向可能不同
               #if UNITY_UV_STARTS_AT_TOP  //判断当前平台是否是DX 平台  如果是DX平台  
               if(_MainTex_TexelSize.y < 0)     //通过判断主纹理纹素值是否小于0 是否开启抗锯齿
               {
                   o.uv_depth.y = 1-o.uv_depth.y;  //如果开启  就要对主纹理外的纹理进行采样竖直坐标翻转
               }
               #endif
                return  o;
            }

            fixed4 frag(v2f i) :SV_Target
            {
                //通过内置的宏和纹理坐标 对深度纹理进行采样  获得深度值d
                float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
                //d是NDC下的坐标映射而来的。构建像素NDC的H  就需要吧d重新映射回NDC  使用原映射的反函数 d*2-1
                float4 H = float4(i.uv.x * 2 -1,i.uv.y * 2 -1,d*2-1,1);
               //当得到NDC下的H  使用当前帧的视角 投影矩阵 的 逆矩阵 进行变化， 
                float4 D = mul(_CurrentViewProjectionInverseMatrix,H);
                //并把结果除以w 得到世界空间下的坐标 worldPos
                float4 worldPos = D/D.w;

                //当前视口位置
                float4 currentPos = H;
                //获得前一帧的NDC下的坐标
                float4 previousPos = mul(_PreviousViewProjectionMatrix,worldPos);
                //把结果除以w 得到世界空间下的坐标 worldPos
                previousPos/= previousPos.w;
                //前一帧-当前帧 获得位置差 得到速度
                float2 velocity = (currentPos.xy - previousPos.xy)/2.0;
                float2 uv = i.uv;
                float4 c = tex2D(_MainTex,uv);
                uv += velocity * _BlurSize;
                //使用速度值对邻域采样  相加后取平均值 得到模糊效果   _BlurSize控制采样距离
                for ( int it = 1; it < 3 ; it++, uv+=velocity *_BlurSize)
                {
                    float4 currentColor = tex2D(_MainTex,uv);
                    c+= currentColor;
                }
                c/=3;
                return  fixed4(c.rgb,1);
            }
            
            ENDCG
        
        Pass
        {
            ZTest Off 
            Cull Off
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
