Shader "Unlit/Chapter11-ScrollingBacground"
{
    Properties
    {
        _MainTex ("Base Layer", 2D) = "white" {}
       _DetailTex("2nd layer",2D) = "white"{}
       _ScrollX("Base Layer X speed",Float) = 1.0
       _Scroll2X("2nd Layer x Speed",float) = 1.0
       _Multiplier("Lyaer Multiplier",float) = 1
    }
    SubShader
    {
        //序列帧动画 多为透明纹理
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType"="Transparent"   }
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;
            half _ScrollX;
            half _Scroll2X;
            half _Multiplier;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };
            
           

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) +frac(float2(_ScrollX,0.0) * _Time.y); //返回标量或者矢量的小数部分
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) +frac(float2(_Scroll2X,0.0) * _Time.y); //返回标量或者矢量的小数部分
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 firstLayer = tex2D(_MainTex,i.uv.xy);
               fixed4 secondLayer = tex2D(_DetailTex,i.uv.zw);
                //混合1 2  layer
               fixed4 c = lerp(firstLayer,secondLayer,secondLayer.a);

               c.rgb *= _Multiplier;

                return c;

            }
            ENDCG
        }
    }
}
