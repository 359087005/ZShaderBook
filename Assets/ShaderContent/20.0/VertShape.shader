// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/ChangeShapeY" {
	Properties{					
		_MainTex("Main",2D)=""{}
		_R("R", range(0,5)) = 2	//半径
		_Center("Center",range(-5,5)) = 0	
		_Scale("Scale", range(0,5)) = 1		
	}
	SubShader {
		pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "unitycg.cginc"
			sampler2D _MainTex;
			float _R;			
			float _Center;
			float _Scale;
			struct v2f {
				float4 vertex:SV_POSITION;
				float4 vpos:TEXCOORD0;	//记录变化后的物体坐标（物体坐标系）
			};
			v2f vert(appdata_base v)
			{
				v2f o;

				o.vpos = v.vertex;
				//o.vpos.y+=0.8*sin((o.vpos.x+o.vpos.z)+_Time.y*0.6);
				//计算物体在xz平面上点与所定义的中心点 float2(_Center,_Center) 的距离
				float dist = distance(o.vpos.xz, float2(_Center,_Center));
				//用定义的半径减去上面求得的距离
				float factor = _R - dist;
				factor = factor < 0 ? 0 : factor;//判断如果小于0则等于0
				o.vpos.y = factor*_Scale ;		 //以这个值作为物体的y坐标
				
				o.vertex = UnityObjectToClipPos(o.vpos);//变换至投影空间
				//o.vpos=v.texcoord;
				return o;
			}
			fixed4 frag(v2f IN):COLOR
			{
				//以物体y坐标来决定物体颜色的三个分量
				float y = saturate(IN.vpos.y);	//saturate取0到1之间的数
				
				return fixed4(y, y, y, 1);

				// fixed4 col = tex2D(_MainTex,IN.vpos);
				// return col;
			}
			ENDCG
		}
	}
}