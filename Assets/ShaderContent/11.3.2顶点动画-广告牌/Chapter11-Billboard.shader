Shader "Unlit/Chapter11-Billboard"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {} //广告牌透明纹理
       
        _VerticalBillboarding("Vertical Restraints",Range(0,1)) = 1    //调整是固定法线还是固定指向上的方向 1固定法线视角  0 固定向上方向 约束垂直方向
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
            
            #include "Lighting.cginc"

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _VerticalBillboarding;

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
                
                float3 center = float3(0,0,0);
                float3 viewDir = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));

                float3 normalDir = viewDir - center;

                normalDir.y = normalDir.y * +_VerticalBillboarding;
                normalDir = normalize(normalDir);

                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0,0,1) : float3(0,1,0);

                float rightDir = normalize(cross(upDir,normalDir));

                upDir = normalize(cross(normalDir,rightDir));

                float3 centerOffs = v.vertex.xyz - center;

                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                o.pos = UnityObjectToClipPos(float4(localPos,1));
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
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
