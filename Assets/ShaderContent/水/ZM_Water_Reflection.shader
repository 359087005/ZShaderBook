Shader "ZM/Scene/Water_Reflection"
{
    Properties
    {
        _MainColor("MainColor",Color) = (1,1,1,1)
        _MainTex ("基础贴图", 2D) = "white" {}
        _Color ("偏色", Color) = (1,1,1,1)
        _Color2 ("远处颜色",Color) = (1,1,1,1)
        _Noise ("扰动纹理", 2D) = "white" {}
        _distortFactorTime("扰动速度",Range(0,5)) = 0.5
        _distortFactorTimeX("扰动速度X",Range(0,5)) = 0.5

        _distortFactor("扰动大小",Range(0.04,5)) = 0
        _LerpTex ("插值贴图", 2D) = "Gray" {}
        _RefIntenstiry("RefIntensity",Range(0,1)) = 0
        [HideInInspector] _ReflectionTex ("", 2D) = "white" {}
        _AlphaMaskTex("AlphaMaskTex",2D) = "white"{}
        _AlphaMaskColor("AlphaMaskColor",Color) = (1,1,1,1)
        }
    SubShader
    {
        Tags  { "RenderType"="Transparent" "Queue" = "AlphaTest" }
        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float2 uv : TEXCOORD0;
                float4 refl : TEXCOORD1;
                float4 pos : POSITION;
                float4 col: COLOR;
            };
            struct v2f
            {
                half2 uv : TEXCOORD0;
                float4 refl : TEXCOORD1;
                float4 pos : SV_POSITION;
                float4 Color2 : TEXCOORD2;
				UNITY_FOG_COORDS(2)

            };
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _LerpTex;
            float4 _LerpTex_ST;
            sampler2D _ReflectionTex;
            sampler2D _Noise,_AlphaMaskTex;
            half4 _AlphaMaskTex_ST;
            float4 _Noise_ST;
            fixed4 _Color2,_MainColor;
            fixed _distortFactorTime,_distortFactorTimeX;
            fixed _distortFactor,_RefIntenstiry;
            fixed4 _AlphaMaskColor;

            v2f vert(appdata_t i)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (i.pos);
                // o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                o.uv = i.uv;
                o.refl = ComputeScreenPos (o.pos);
                o.Color2 = i.col;
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //half4 AlphaTex = tex2D(_AlphaMaskTex,TRANSFORM_TEX(i.uv,_AlphaMaskTex));
                fixed4 bias = tex2D(_Noise,TRANSFORM_TEX(i.uv,_Noise)+half2(_Time.y*_distortFactorTime,_Time.y*_distortFactorTimeX));
                fixed4 tex = tex2D(_MainTex, TRANSFORM_TEX(i.uv,_MainTex)) ;
                fixed4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.refl+bias*_distortFactor));
                fixed4 lerpvalue = tex2D(_LerpTex,TRANSFORM_TEX(i.uv,_LerpTex));
                fixed4 col = lerp(refl*_Color,tex*_Color2,saturate(lerpvalue.r+_RefIntenstiry))*_MainColor;
                //col.rgb = lerp(_AlphaMaskColor.rgb,col.rgb,AlphaTex.r);
                col.a = i.Color2.a;
                UNITY_APPLY_FOG(i.fogCoord,col);
                return col;
            }
            ENDCG
        }
    }
}