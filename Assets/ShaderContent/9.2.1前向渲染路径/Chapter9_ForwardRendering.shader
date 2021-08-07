//我想是是是
Shader "Chapter9/Forward Rendering" {
	Properties{
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
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
		};

		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex); //模型空间转裁剪空间

			o.worldNormal = UnityObjectToWorldNormal(v.normal); //法线转世界

			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;//模型空间转世界

			return o;
		}

		fixed4 frag(v2f i) : SV_Target {
			fixed3 worldNormal = normalize(i.worldNormal);
			fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);  //指向光源的方向。 如果 _WorldSpaceLightPos0.w为0，表示该光源为平行光。_WorldSpaceLightPos0.w为1。则表示光源为点光源或聚光灯。

			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; //环境光
			//兰伯特光照公式diffuse = light颜色* Diffuse 颜色 *saturate(N · L)；        dot(n,l)
			fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir)); 
			//模型到摄像机的向量
			fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz); 
			//blinn-phone高光反射公式specular = light颜色*specular颜色 * max（0，V · h)^gloss；
			fixed3 halfDir = normalize(worldLightDir + viewDir); //
			fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

			fixed atten = 1.0;  //衰减值   平行光无衰减

			return fixed4(ambient + (diffuse + specular) * atten, 1.0);
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
				#ifdef USING_DIRECTIONAL_LIGHT		//判断光源类型    
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);  //平行光光源方向可以通过该函数直接获得
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);//在其他光源 _WorldSpaceLightPos0表示世界空间下光源位置  光源方向需要减去世界空间下定点位置
				#endif

				//兰伯特光照diffuse = light颜色* Diffuse 颜色 *saturate(N · L)；        dot(n,l)
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
				//模型到摄像机的向量
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

				//blinn-phone高光反射公式specular = light颜色*specular颜色 * max（0，V · h)^gloss；
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				//根据光照类型 设置衰减值
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
				#else
					#if defined (POINT)
						float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
						fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
					#elif defined (SPOT)
						float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
						fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
					#else
						fixed atten = 1.0;
					#endif
				#endif

				return fixed4((diffuse + specular) * atten, 1.0);
			}

			ENDCG
		}
	}
		FallBack "Specular"
}