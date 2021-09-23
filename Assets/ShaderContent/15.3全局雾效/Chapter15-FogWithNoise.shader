Shader "Unlit/Chapter15-FogWithNoise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogDensity("Fogdensity",float) = 1
        _FogColor("Fog Color",Color) = (1,1,1,1)
        _FogStart("Fog Start",float) =  0
        _FogEnd("Fog End",float) = 1
        
        
        
    }
    SubShader
    {
            CGINCLUDE

            #include  "UnityCG.cginc"
            
            #pragma multi_compile_fog
            float4x4 _FrustumCornersRay;
            sampler2D _MainTex;
            half4 _MainTex_TexelSize;
            sampler2D _CameraDepthTexture;
            half _FogDensity;
            half4 _FogColor;
            float _FogStart,_FogEnd;


            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                half2 uv_depth : TEXCOORD1;
                float4 interpolatedRay :TEXCOORD2;
            };

            v2f vert(appdata_img v)
            {
                v2f o ;
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

                int index = 0;
                if(v.texcoord.x < 0.5f && v.texcoord.y <0.5)
                {
                    index =0;
                }
                else if(v.texcoord.x > 0.5f && v.texcoord.y <0.5)
                {
                    index = 1;                    
                }
                else if(v.texcoord.x > 0.5f && v.texcoord.y > 0.5)
                {
                    index = 2;
                }
                else index =3;

                       //纹理坐标差异化处理     DX平台 开启抗锯齿处理多张渲染图像   图像在竖直方向的朝向可能不同
               #if UNITY_UV_STARTS_AT_TOP  //判断当前平台是否是DX 平台  如果是DX平台  
               if(_MainTex_TexelSize.y < 0)     //通过判断主纹理纹素值是否小于0 是否开启抗锯齿
               {
                 index = 3 - index;
               }
               #endif

                o.interpolatedRay = _FrustumCornersRay[index];
                return  o;
            }

            fixed4 frag(v2f i): SV_Target
            {
                float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth));
                float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
                float fogDensity = (_FogEnd - worldPos.y)/(_FogEnd - _FogStart);
                fogDensity = saturate(fogDensity* _FogDensity);

                fixed4 finnalColor = tex2D(_MainTex,i.uv);
                finnalColor.rgb = lerp(finnalColor.rgb,_FogColor.rgb,fogDensity);
                return  finnalColor;
            }
            
            #include "UnityCG.cginc"
            ENDCG
        
        Pass
            {
                ZTest Off
                Cull Off
                ZWrite Off
                
                CGPROGRAM
                #pragma vertex vert
                #pragma  fragment frag
                ENDCG
            }
    }
}
