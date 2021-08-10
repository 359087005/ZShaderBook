Shader "Unlit/Chapter12-BrightSatContrast"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  //Graphics.Blit 必须要有个_Maintex参数
        _Brightness("_Brightness",float) = 1
        _Saturation("_Brightness",float) = 1
        _Contrast("_Brightness",float) = 1
    }
    SubShader
    {
        Pass
        {
            ZTest Always 
            Cull Off 
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Brightness,_Saturation,_Contrast;
      
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };


            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 renderTex = tex2D(_MainTex,i.uv);

                fixed3 finalColor = renderTex.rgb * _Brightness; //亮度 原颜色乘以亮度系数即可

                //然后计算该像素的亮度值  系数是特定的...
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                //可获得一个饱和度为0的颜色值
                fixed3 luminanceColor = fixed3(luminance,luminance,luminance);
                //差值获得希望的颜色
                finalColor = lerp(luminanceColor,finalColor,_Saturation);
                //对比度类似
                fixed3 avgColor = fixed3(.5,.5,.5);
                finalColor = lerp(avgColor,finalColor,_Contrast);

                return  fixed4(finalColor,renderTex.a);
            }
            ENDCG
        }
    }
}
