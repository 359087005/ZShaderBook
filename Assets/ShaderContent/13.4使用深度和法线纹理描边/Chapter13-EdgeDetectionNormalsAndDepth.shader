Shader "Unlit/Chapter13-EdgeDetectionNormalsAndDepth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
         _EdgeOnly("Edge Only",float) = 1
        _EdgeColor("Edge Color",Color) = (0,0,0,1)
        _BackgroundColor("Background Color",Color) = (1,1,1,1)
        
        _SampleDistance("Sample Distanec",float) = 1
        _Sensitivity("Sensityvity",vector) = (1,1,1,1)  //xy 对象法线和深度的灵敏度  zw无用
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half4 _MainTex_TexelSize; //访问纹理的纹素的大小   1/分辨率
            fixed _EdgeOnly;
            fixed4 _EdgeColor,_BackgroundColor;
            float _SampleDistance;
            half4 _Sensitivity;
            sampler2D _CameraDepthNormalsTexture;

        struct  v2f
        {
            float4 pos :SV_POSITION;
            half2 uv[5] :TEXCOORD0;
        };

        v2f vert(appdata_img v)
        {
            v2f o ;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;
            o.uv[0] = uv;
            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y<0)
            {
                uv.y = 1 - uv.y;
            }
            #endif

            o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) *_SampleDistance;
            o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) *_SampleDistance;
            o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) *_SampleDistance;
            o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) *_SampleDistance;
            return  o;
        }

        //计算对角线上的纹理值差值  要么返回0  两点之间有边界  要么返回1
        half CheckSame(half4 center,half4 sample)
        {
            half2 centerNormal = center.xy;
            float centerdepth = DecodeFloatRG(center.zw);
            half2 sampleNormal = sample.xy;
            float sampleDepth = DecodeFloatRG(sample.zw);
            //法线不同
            half2 diffNormal = abs(centerNormal-sampleNormal) * _Sensitivity.x;
            int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
            //深度不同
            float diffDepth = abs(centerdepth-sampleDepth) * _Sensitivity.y;
            int isSameDepth = diffDepth < 0.1 * centerdepth;
            
            return isSameNormal * isSameDepth ? 1.0 :0.0;
        }

        //4个纹理坐标对深度和法线进行采样
        fixed4 fragRobertsCrossDepthAndNormal(v2f i) :SV_Target
        {
            half4 sampler1 = tex2D(_CameraDepthNormalsTexture,i.uv[1]);
            half4 sampler2 = tex2D(_CameraDepthNormalsTexture,i.uv[2]);
            half4 sampler3 = tex2D(_CameraDepthNormalsTexture,i.uv[3]);
            half4 sampler4 = tex2D(_CameraDepthNormalsTexture,i.uv[4]);
        
            half edge = 1.0;

             edge *= CheckSame(sampler1,sampler2);
             edge *= CheckSame(sampler3,sampler4);

            fixed4 withEdgeColor = lerp(_EdgeColor,tex2D(_MainTex,i.uv[0]),edge);
            fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);

            return lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);
        }

        
        ENDCG
       
        
        
        Pass
        {
            ZTest Always 
            Cull Off 
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRobertsCrossDepthAndNormal

            ENDCG
        }
    }
    FallBack Off
}
