Shader "Unlit/LightShadow"
{
    Properties
    {
        _MainColor("Main Color",Color) = (1,1,1,1)
        
        _SpecularColor("Specular Color",Color) = (1,1,1,1)
        _SpecularPow("Specular Pow",float) = 30
        _SpecularStrength("Specular Strength",float) = 1
        
        _AOTexture("AO Texture",2D) = "white"{}
        
        _EnvUpColor("Env Up Color",color) = (1,1,1,1)
        _EnvMiddleColor("Env Middle Color",Color) = (1,1,1,1)
        _EnvDownColor("Env Down Color",Color) = (1,1,1,1)
        _EnvStrength("Env Strength",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            Tags 
            {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include  "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
            
            fixed4 _MainColor,_SpecularColor,_EnvUpColor,_EnvMiddleColor,_EnvDownColor;
            float _SpecularPow,_SpecularStrength,_EnvStrength;
            sampler2D _AOTexture;
            float4 _AOTexture_ST;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float3 worldNormal:TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = v.uv;
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 l = normalize(_WorldSpaceLightPos0);
                fixed3 n = normalize(i.worldNormal);
                fixed3 v = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 r = reflect(-l,n);
                
                float ndl = saturate(dot(n,l));
                fixed3 diffuseColor = ndl * _MainColor;
                
                fixed3 rdv = saturate(dot(r,v));
                fixed3 specularColor = pow(rdv,_SpecularPow) * _SpecularStrength * _SpecularColor;

                float shadow =  LIGHT_ATTENUATION(i);
                fixed3 color1 = (diffuseColor + specularColor ) * _LightColor0 * shadow;
                
                //环境光照
                fixed up = saturate(n.g);
                fixed down = saturate(-n.g);
                fixed middle = 1-up-down;
                fixed3 upColor = up * _EnvUpColor;
                fixed3 downColor = down * _EnvDownColor;
                fixed3 middleColor = middle * _EnvMiddleColor;
                fixed3 envColor = (upColor + downColor + middleColor) * _EnvStrength;
                fixed3 AOColor = tex2D(_AOTexture,i.uv);
                
                fixed3 color2 =envColor * AOColor * _MainColor;

                return fixed4( color2 + color1,1);
                //return  shadow;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
