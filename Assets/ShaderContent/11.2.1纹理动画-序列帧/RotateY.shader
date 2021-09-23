Shader "Unlit/RotateY"
{
    Properties
    {
        _XRotate("X",Range(-1,1)) = 0
        _YRotate("Y",Range(-1,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };
            float _XRotate,_YRotate;
            float3 xyzPos;
            
            float4x4 rotate()
            {
                float4x4 R_X =
                    {
                        cos(_YRotate),  0,              sin(_YRotate),                 xyzPos.x,
                        0,              cos(_XRotate),      sin(_XRotate),             xyzPos.y,
                        -sin(_YRotate), -sin(_XRotate),   cos(_XRotate +_YRotate) ,    xyzPos.z,
                        0,                  0,              0,                          1,
                    };
               return R_X;
            };
            v2f vert (appdata v)
            {
                v2f o;
                v.vertex = mul(rotate(),v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            fixed4 frag () : SV_Target
            {
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
    }
}
