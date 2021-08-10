﻿Shader "Unlit/Chapter12-MotionBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} //输入的渲染纹理
        
        _BlurAmount("Blur Amount" ,float) = 1 //混合图像时使用的混合系数
    }
    SubShader
    {
            CGINCLUDE

            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float _BlurAmount;
            struct v2f
            {
                float4 pos :SV_POSITION;
                half2 uv :TEXCOORD0;
            };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;
                return  o;
            }

            fixed4 fragRGB(v2f i) :SV_Target
            {
                return  fixed4(tex2D(_MainTex,i.uv).rgb,_BlurAmount);;
            }

           half4 fragA(v2f i):SV_Target
            {
                return  tex2D(_MainTex,i.uv);
            }
            ENDCG
        
            ZTest Always
            Cull Off
            ZWrite Off
            
        Pass
           {
               Blend SrcAlpha OneMinusSrcAlpha
               ColorMask RGB
               CGPROGRAM
                #pragma vertex vert
               #pragma  fragment fragRGB
               ENDCG
            }
        
        Pass
        {
            Blend One Zero
            ColorMask A
             CGPROGRAM
                #pragma vertex vert
               #pragma  fragment fragA
               ENDCG
}
    }
}
