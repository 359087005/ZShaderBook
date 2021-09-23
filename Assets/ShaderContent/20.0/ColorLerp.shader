// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ColorLerp"
{
    Properties
    {
       _MainColor("MainColor", color) = (0,1,0,1)           //第一种颜色：绿
		_SecondColor("SecondColor", color) = (1,0,0,1) //第二种颜色：红
		_Center("Center", range(-0.51,0.51)) = 0              //中心点y坐标值
		_R("R", range(0,1)) = 0.2                                         //产生渐变的范围值
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

       pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "unitycg.cginc"
			fixed4 _MainColor;
			fixed4 _SecondColor;
			float _Center;
			float _R;
			struct v2f {
				float4 pos:POSITION;
				float y : TEXCOORD0;
			};
			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.y = v.vertex.y;
				return o;
			}
			fixed4 frag(v2f IN):COLOR
			{
				float y = IN.y;
				float s = y -( _Center - _R/2);
				float f = saturate(s / _R);
				fixed4 col = lerp(_MainColor, _SecondColor,f);
				return col;
			}
			ENDCG
		}
    }
}
