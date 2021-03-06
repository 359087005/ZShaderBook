
Shader "Chapter9/PointLight" {
	Properties{
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
		//_PointLightPos("_PointLightPos",Vector) = (1,0,0,0)
		_pointLightColor("_pointLightColor",Color) = (1,1,1,1)
		_PointLightIntensity("_PointLightStrength",Range(0,10)) = 1
		_PointLightRange("_P_PointLightRange",Range(0,100)) = 1
		_PointLightAtten("_PointLightAtten",Range(0,10)) = 1
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }

			Pass {
				Tags { "LightMode" = "ForwardBase" }
				
				CGPROGRAM

		// Apparently need to add this declaration 
		#pragma multi_compile_fwdbase	 //该指令可以保证我们使用关照衰减等 光照变量可以被正确赋值

		#pragma vertex vert
		#pragma fragment frag

		#include "Lighting.cginc"
		#include "AutoLight.cginc"
				
		fixed4 _Diffuse;
		fixed4 _Specular;
		float _Gloss;

		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
		};

		struct v2f {
			float4 pos : SV_POSITION;
			float3 worldNormal : TEXCOORD0;
			float3 worldPos : TEXCOORD1;
			SHADOW_COORDS(2) //声明一个用于对阴影纹理采样的坐标 参数是下一个可用的插值寄存器的索引值
		};

		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex); //模型空间转裁剪空间

			o.worldNormal = UnityObjectToWorldNormal(v.normal); //法线转世界

			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;//模型空间转世界

			//TRANSFER_SHADOW(o) //在顶点计算器计算上一步中声明的阴影纹理坐标   把顶点坐标从模型空间变换到光源空间
			
			return o;
		}

		fixed4 frag(v2f i) : SV_Target {

			//fixed shadow = SHADOW_ATTENUATION(i);  //使用_ShadowCoord 对相关纹理进行采样获得阴影信息
			
			fixed3 worldNormal = normalize(i.worldNormal);
			fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);  //指向光源的方向。 如果 _WorldSpaceLightPos0.w为0，表示该光源为平行光。_WorldSpaceLightPos0.w为1。则表示光源为点光源或聚光灯。

			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; //环境光
			//兰伯特光照公式diffuse = light颜色* Diffuse 颜色 *saturate(N · L)；        dot(n,l)
			fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir) * 0.5 + 0.5); 
			//模型到摄像机的向量
			fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz); 
			//blinn-phone高光反射公式specular = light颜色*specular颜色 * max（0，V · h)^gloss；
			fixed3 halfDir = normalize(worldLightDir + viewDir); //
			fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

			UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos); //Unity内置计算光照衰减和阴影的宏   将光照衰减和阴影值相乘后的结果存储到第一个参数中.  自动声明第一个参数
			
			return fixed4(ambient + (diffuse + specular) * atten , 1.0);

			//return fixed4(diffuse * atten , 1.0);
		}

		ENDCG
	}

	Pass {
			// Pass for other pixel lights
				Tags { "LightMode" = "ForwardAdd" }

			Blend One One  // 开启混合  否则会覆盖掉之前的光照

			CGPROGRAM

			// Apparently need to add this declaration
			#pragma multi_compile_fwdadd    //该指令确保我们在Add pass  可以访问到正确光照变量

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			float4 _PointLightPos,_pointLightColor;
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
				fixed3 diffuse = _pointLightColor.rgb * _Diffuse.rgb * max(0,  ndl );
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
				//return fixed4(ndl*0.1,ndl*0.1,ndl*0.1, 1.0);
			}
			ENDCG
		}
	}
}