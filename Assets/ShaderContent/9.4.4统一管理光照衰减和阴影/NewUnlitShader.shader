Shader "Unlit/NewUnlitShader"
{
    Properties
    {
    	_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
    	_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
    	
    	_pointLightColor("_pointLightColor",Color) = (1,1,1,1)
		_PointLightIntensity("_PointLightStrength",Range(0,10)) = 1
		_PointLightRange("_P_PointLightRange",Range(0,100)) = 1
		_PointLightAtten("_PointLightAtten",Range(0,10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

      Pass {
			// Pass for other pixel lights
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			 float4 _PointLightPos;
			float4 _pointLightColor;
			float _PointLightIntensity,_PointLightRange,_PointLightAtten;
			
			float _fAttenuation0;
			float _fAttenuation1;
			float _fAttenuation2;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);  //模型空间转裁剪空间

				o.worldNormal = UnityObjectToWorldNormal(v.normal); //法线  模型到世界

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; //定点 模型到世界
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir =normalize( _PointLightPos - i.worldPos);//在其他光源 _WorldSpaceLightPos0表示世界空间下光源位置  光源方向需要减去世界空间下定点位置

				//兰伯特光照diffuse = light颜色* Diffuse 颜色 *saturate(N · L)；        dot(n,l)
				float ndl = dot(worldNormal, worldLightDir);
				fixed3 diffuse = _pointLightColor.rgb * _Diffuse.rgb * saturate(ndl);
				//模型到摄像机的向量
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _pointLightColor.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				//根据光照类型 设置衰减值
				float distance = length(worldLightDir);
				clamp(distance,0,_PointLightRange);
				float disAtten = 1/(1+_PointLightAtten*_PointLightAtten*distance * distance);
				//atten*= _PointLightIntensity;
				return fixed4((diffuse + specular ) * disAtten  , 1.0);
				//return fixed4(diffuse, 1.0);
			}
			ENDCG
		}
    }
}
