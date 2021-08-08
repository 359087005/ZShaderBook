Shader "Unlit/Chapter11-Water"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Base Layer", 2D) = "white" {}
        _Magnitude("Distortion Magnitude",float) = 1        //控制水流波动幅度
        _Frequency("Distortion Frequency",float)  = 1       //控制波动频率
        _invWaveLength("Distortion Inverse Wave Length",float) = 10   //控制波长倒数   值越大 波长越小
        _Speed("Speed",float) = 0.5   //控制水流速度
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType"="Transparent"  "DisableBatching" = "True" }
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Magnitude,_Frequency,_invWaveLength,_Speed;

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
                float4 offset;
                offset.xyz = float3(0,0,0);
                offset.x = sin(_Frequency * _Time.y + v.vertex.x * _invWaveLength + 
                                                      v.vertex.y * _invWaveLength + 
                                                      v.vertex.z * _invWaveLength) * _Magnitude;
                o.pos = UnityObjectToClipPos(v.vertex + offset);
              
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                o.uv += float2(0.0,_Time.y * _Speed);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 c = tex2D(_MainTex,i.uv);
                //混合1 2  layer
                c.rgb *= _Color.rgb;
                return c;

            }
            ENDCG
        }
    }
}
