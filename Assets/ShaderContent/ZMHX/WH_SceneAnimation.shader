Shader "ZM/Scene/WH_SceneAnimation"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        [Header(Animation)]
		_DistortionTex("DistortionTex", 2D) = "white" {}
		_U_Speed("U_Speed", Float) = 0
		_V_Speed("V_Speed", Float) = 0
		_DistortionIntensity("DistortionIntensity", Float) = 0
		_Mask("Mask", 2D) = "white" {}
        [Header(Other)]
        _AddTexture("AddTexture",2D) = "white"{}
        _AddColor("AddColor",Color) = (1,1,1,0)
        [Toggle]_AddAlpha("AddAlpha",Float) = 0
    }
    SubShader
    {
        //如果想要修改渲染队列 必须要关闭深度写入   如果要修改透明  必须要blend
        Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back   //不渲染背面
        Blend SrcAlpha OneMinusSrcAlpha     
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog   //使该shader可以接受scene的fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)////雾数据
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex,_DistortionTex,_Mask,_AddTexture;
            float4 _MainTex_ST,_DistortionTex_ST,_Mask_ST,_AddTexture_ST,_AddColor;
            half _U_Speed,_V_Speed,_DistortionIntensity,_AddAlpha;
            
            v2f vert (appdata v)
            {
                v2f o;  
                o.vertex = UnityObjectToClipPos(v.vertex);  //顶点坐标 从模型空间转换到裁剪空间
                o.uv = v.uv; //
                UNITY_TRANSFER_FOG(o,o.vertex); //从顶点着色器中输出雾效数据
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
            //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的。
            // 两个函数等价
            //o.uv =   TRANSFORM_TEX(v.texcoord,_MainTex);
            //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                float2 uv_MainTexture = i.uv *_MainTex_ST.xy+_MainTex_ST.zw;
                float2 uv_DistortionTex = i.uv *_DistortionTex_ST.xy+_DistortionTex_ST.zw;
			    float2 uv_Mask = i.uv * _Mask_ST.xy + _Mask_ST.zw;

                float2 appendSpeed = half2(_U_Speed,_V_Speed);
                // float2 rotator24 = ( ( uv_DistortionTex + ( appendSpeed*_Time.y)%1 ));
                float2 rotator24 = float2(uv_DistortionTex.x+appendSpeed.x*(frac(_Time.y*_U_Speed)*1/_U_Speed),uv_DistortionTex.y);

                half4 addTextureVar = tex2D(_AddTexture,TRANSFORM_TEX(i.uv,_AddTexture));

			    float4 col = tex2D( _MainTex, ( uv_MainTexture + ( ( ( tex2D( _DistortionTex, rotator24 ).r)) * _DistortionIntensity * tex2D( _Mask, uv_Mask ).r ) ) );
                UNITY_APPLY_FOG(i.fogCoord, col); //将第二个参数中的颜色值作为雾效的颜色值

                half3 outcolor = lerp(_AddColor,col.rgb,addTextureVar.r);

                return float4(lerp(col.rgb,outcolor,_AddColor.a),lerp(col.a,addTextureVar.r*col.a,_AddAlpha));
            }
            ENDCG
        }
    }
}
