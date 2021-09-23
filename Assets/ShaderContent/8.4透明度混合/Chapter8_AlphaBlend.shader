
Shader "UNITY SHADER BOOK/AlphaBlend"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
    	_MainTex("Main Tex",2D) = "white"{}
    	_AlphaScale("Alpha Scale",Range(0,1)) = 0.5
    }
    SubShader
    {
       Tags  {"Queue" = "Transparent" "IgnoreProjector" = "true" "RenderType" = "Transparent"}
       Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            ZWrite Off          
            Blend SrcAlpha OneMinusSrcAlpha   

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
			sampler2D _MainTex;   //
            float4 _MainTex_ST; 
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0; 
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 uv : TEXCOORD2;
            };
       
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.worldNormal = UnityObjectToWorldNormal(v.normal); 
            o.worldPos =mul( unity_ObjectToWorld,v.vertex).xyz;  
            o.uv = v.texcoord;
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            fixed3 albedo = tex2D(_MainTex, i.uv)  * _Color.rgb;//采样贴图
            fixed3 worldNormal = normalize(i.worldNormal);
            //fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
            fixed3 viewDir = UnityWorldSpaceViewDir(i.worldPos);
            fixed3 diffuse = _LightColor0.rgb * albedo *  saturate(dot(worldNormal,viewDir));
            fixed3 finalColor =  _LightColor0.rgb * diffuse * albedo;
            return fixed4(finalColor ,  _AlphaScale);
        }
        ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
