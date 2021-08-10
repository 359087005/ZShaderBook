Shader "Unlit/Chapter12-Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  //对应输入的渲染纹理
        _Bloom("Bloom",2D) = "black"{}   //高斯模糊后 较亮区域
        _LuminanceThreshold("luminance Threshold",float) = 0.5  //提取较亮区域的阈值
        _BlurSize("Blur Size",float) =  1 //控制不同迭代之间高斯模糊的模糊区域范围
    }
    SubShader
    {
           CGINCLUDE

           #include "UnityCG.cginc"
           
           sampler2D _MainTex;
           half4 _MainTex_TexelSize; //纹素值
           sampler2D _Bloom;
           float _LuminanceThreshold,_BlurSize;

           struct v2f
           {
               float4 pos :SV_POSITION;
               float2 uv : TEXCOORD;
           };
           v2f vertExtractBright(appdata_img v)
           {
               v2f o;
               o.pos = UnityObjectToClipPos(v.vertex);
               o.uv = v.texcoord;
               return  o;
           }

           fixed luminance(fixed4 color)
           {
               return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
           }

           fixed4 fragExtractBright(v2f i) : SV_Target
           {
               fixed4 c = tex2D(_MainTex,i.uv);
               fixed val = clamp(luminance(c) - _LuminanceThreshold,0.0,1.0); //限制值在（x,a,b） ab之间，最小为a 最大为b
               return  c * val;
           }

           struct v2fBloom
           {
               float4 pos : SV_POSITION;
               half4 uv :TEXCOORD0;
           };

           struct v2fGaussian
            {
                float4 pos : SV_POSITION;
                half2 uv[5] : TEXCOORD0;

            };

           v2fBloom vertBloom(appdata_img v)
           {
                v2fBloom o;
               o.pos = UnityObjectToClipPos(v.vertex);
               o.uv.xy = v.texcoord;   //原图像纹理坐标
               o.uv.zw = v.texcoord;//模糊后较亮区域的纹理坐标

               //纹理坐标差异化处理     DX平台 开启抗锯齿处理多张渲染图像   图像在竖直方向的朝向可能不同
               #if UNITY_UV_STARTS_AT_TOP  //判断当前平台是否是DX 平台  如果是DX平台  
               if(_MainTex_TexelSize.y < 0)     //通过判断主纹理纹素值是否小于0 是否开启抗锯齿
               {
                   o.uv.w = 1-o.uv.w;  //如果开启  就要对主纹理外的纹理进行采样竖直坐标翻转
               }
               #endif

               return  o;
           }
           fixed4 fragBloom(v2fBloom i) :SV_Target
           {
               return  tex2D(_MainTex,i.uv.xy) + tex2D(_Bloom,i.uv.zw);
           }

            v2fGaussian vertBlurVertical (appdata_img v)
            {
                v2fGaussian o;
                o.pos = UnityObjectToClipPos(v.vertex);
               half2 uv = v.texcoord; 
               o.uv[0] = uv;
               o.uv[1] = uv + float2(0.0,_MainTex_TexelSize.y * 1.0) * _BlurSize;
               o.uv[2] = uv - float2(0.0,_MainTex_TexelSize.y * 1.0) * _BlurSize;
               o.uv[3] = uv + float2(0.0,_MainTex_TexelSize.y * 2.0) * _BlurSize;
               o.uv[4] = uv - float2(0.0,_MainTex_TexelSize.y * 2.0) * _BlurSize;
                return o;
            }
            v2fGaussian vertBlurHorizontal(appdata_img v)
            {
			v2fGaussian o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
			}

           fixed4 fragBlur (v2fGaussian i) : SV_Target
            {
               float weight[3] = {0.4026,0.2442,0.0545};

                fixed3 sum = tex2D(_MainTex,i.uv[0]).rgb * weight[0];

                for (int it =1; it < 3; it++)
                {
                     sum += tex2D(_MainTex,i.uv[it*2-1]).rgb * weight[it];
                     sum += tex2D(_MainTex,i.uv[it*2]).rgb * weight[it]; 
                }

                return  fixed4(sum,1);
            }
           ENDCG
        
        ZTest Always
        Cull Off
        ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma  fragment fragExtractBright
            ENDCG
        }
        
         Pass
            {
                NAME  "GAUSSIAN_BLUR_VERTICAL"
                CGPROGRAM
                #pragma  vertex vertBlurVertical
                #pragma  fragment fragBlur
                ENDCG
            }
        
          Pass
            {
                NAME  "GAUSSIAN_BLUR_VERTICAL"
                CGPROGRAM
                #pragma  vertex vertBlurHorizontal
                #pragma  fragment fragBlur
                ENDCG
            }
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma  fragment fragBloom
            ENDCG
        }
    }
}
