Shader "Unlit/Chapter11-ImageSequenceAnimation"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _HorizontalAmount("Horizontal Amount",float) =4
        _VerticalAmount("Vertical Amount",float) = 4
        _Speed("Speed",float) = 30
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

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _HorizontalAmount;
            half _VerticalAmount;
            half _Speed;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };
            
           

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = floor(_Time.y * _Speed); //向下取整  0  1   2   3  4    5   6   7   
                float row = floor(time/_HorizontalAmount); //行   0  0  0   0   1    1   1  1    
                float column = time - row*_VerticalAmount;//列    0   1  2   3  0    1   2   3

                //根据行列总数 进行uv 块划分    左上角第一块的uv

                //这个UV.x 加上  列数站行数的百分比  获得uv.x 的偏移
                //UV的原点在左下方   所以uv.y 减去 第几行 占 vertical的百分比

                // half uv  = float2(i.uv.x/_HorizontalAmount,i.uv.y/_VerticalAmount);
                // uv.x += column /_HorizontalAmount;
                // uv.y -= row / _VerticalAmount;

                half2 uv = i.uv + half2(column,-row);
                uv.x/=_HorizontalAmount;
                uv.y/=_VerticalAmount;

                fixed4 c = tex2D(_MainTex,uv);
                c.rgb *= _Color;
                return c;

            }
            ENDCG
        }
    }
}
