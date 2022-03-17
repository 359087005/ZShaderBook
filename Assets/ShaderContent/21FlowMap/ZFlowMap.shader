Shader "Unlit/ZFlowMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _Color("Color",Color) = (1,1,1,1)
        
        _FlowMap("FlowMap",2D) = "white"{}
        _FlowSpeed("flowSpeed",float) = 0.1
        _TimeSpeed("TimeSpeed",float) = 1
        
        
    }
    SubShader
    {
        Tags 
        {
             "RenderType"="Opaque" 
        }
        Cull off
        lighting off
        ZWrite on      
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _FlowMap;
            fixed4 _Color;
            float _FlowSpeed,_TimeSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
               
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 flowDir = tex2D(_FlowMap,i.uv) *2-1; //获取流向   从0-1 变更到-1-1

                flowDir*= -_FlowSpeed;

                //构造波形函数
                float phase0 = frac(_Time*0.1 * _TimeSpeed);
                float phase1 = frac(_Time * 0.1 * _TimeSpeed+0.5);

                //计算平铺偏移后的UV
                float2 tilling_uv = i.uv * _MainTex_ST.xy + _MainTex_ST.zw;

                //根据uv和波形函数进行采样
                half3 tex0 = tex2D(_MainTex,tilling_uv - flowDir * phase0);
                half3 tex1 = tex2D(_MainTex,tilling_uv - flowDir * phase1);
                //获取插值
                float flowLerp = abs((0.5 - phase0)/0.5);
                //根据插值进行颜色采样
                half3 finnalColor = lerp(tex0,tex1,flowLerp);
                
                fixed4 col = float4(finnalColor,1) * _Color;
                return col;
            }
            ENDCG
        }
    }
}
