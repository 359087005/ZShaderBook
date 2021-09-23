Shader "Arc/ArcWritePbr"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}  //物体贴图
		_Tint("Tint", Color) = (1 ,1 ,1 ,1)
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0 //金属度要经过伽马校正
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_LUT("LUT", 2D) = "white" {}   //查找表的贴图
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			Tags {
				"LightMode" = "ForwardBase"
			}
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityStandardBRDF.cginc" 
			
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};
			
			float4 _Tint;
			float _Metallic;
			float _Smoothness;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _LUT;
			
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.normal = normalize(o.normal);
				return o;
			}
			
			float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
			{
				return F0 + (max(float3(1 ,1, 1) * (1 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				i.normal = normalize(i.normal);    
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);     //光方向
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz); //视角方向
				float3 lightColor = _LightColor0.rgb;		//灯光颜色  系统内置的
				float3 halfVector = normalize(lightDir + viewDir);  //半角向量

				float perceptualRoughness = 1 - _Smoothness;  //粗糙度

				float roughness = perceptualRoughness * perceptualRoughness; //粗糙度平方
				float squareRoughness = roughness * roughness;   //粗糙度 4次方

				float nl = max(saturate(dot(i.normal, lightDir)), 0.000001);//防止除0
				float nv = max(saturate(dot(i.normal, viewDir)), 0.000001);
				float vh = max(saturate(dot(viewDir, halfVector)), 0.000001);
				float lh = max(saturate(dot(lightDir, halfVector)), 0.000001);
				float nh = max(saturate(dot(i.normal, halfVector)), 0.000001);


				//BRDF中 直接光漫反射   输出颜色 = 纹理颜色/PI * 光源颜色 * NDL(灯光和法线的点乘)   
				//但是BRDF中并没有除 1，为了保证shader和legacy差不多亮   2,避免对not important 光源做特殊处理
				
				
				float3 Albedo = _Tint * tex2D(_MainTex, i.uv);  //常规操作  采样 乘以 颜色

				//BRDF 直接光镜面反射    输出颜色 = DFG /  ( 4 x  nv  x nl )
				//    					D 法线分布函数	D = 粗糙度平方 / （（  NDH平方  * （粗糙度平方  - 1）  + 1 ）的平方 乘以 PI）
				// 						F 菲涅尔		F = F0 + (1-F0)  ((1-nl)5次方) 
				//						G 几何函数  G =  G1 * G2    G1 = nl / (lerp(nl,1,k))     G2 = nv / lerp(nv,l,k)   
				//													k在直接光照时 = (粗糙度+1)的平方/8   在间接光照时  = 粗糙度平方/2

				float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);//Unity把roughness lerp到了0.002
				//D 法线分布函数	D = 粗糙度平方 / （（  NDH平方  * （粗糙度平方  - 1）  + 1 ）的平方 乘以 PI）
				float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);

				//G 几何函数  G =  G1 * G2    G1 = nl / (lerp(nl,1,k))     G2 = nv / lerp(nv,l,k)   
				//k在直接光照时 = (粗糙度+1)的平方/8   在间接光照时  = 粗糙度平方/2
				float kInDirectLight = pow(squareRoughness + 1, 2) / 8;
				//float kInIBL = pow(squareRoughness, 2) / 8;
				float GLeft = nl / lerp(nl, 1, kInDirectLight);
				float GRight = nv / lerp(nv, 1, kInDirectLight);
				float G = GLeft * GRight;
				float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, Albedo, _Metallic);
				float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);
				float3 SpecularResult = (D * G * F * 0.25) / (nv * nl);
				//间接光的实现和 ibl基于图像渲染  SH球和谐光
				//间接光漫反射
				float3 kd = (1 - F)*(1 - _Metallic);
				//直接光照镜面反射
				float3 specColor = SpecularResult * lightColor * nl * UNITY_PI;
				float3 diffColor = kd * Albedo * lightColor * nl;   //忽视kd就是个兰伯特公式
				float3 DirectLightResult = diffColor + specColor;
				//unitycg.cginc 直接调用其中的shaderSH9方法 传入归一化法线 返回重建的积分环境光照信息
				half3 ambient_contrib = ShadeSH9(float4(i.normal, 1));
				//随便给了个值意思意思  影响不大
				float3 ambient = 0.03 * Albedo;
				float3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);
				//间接光镜面反射
				//把cubemap渲染成一张带LOD的贴图  三次线采样   unity_SpecCube0 这张图在这里(存储的是场景和天空盒的反射数据)
				//对采样用的粗糙度计算(unity的粗糙度和mipmap等级不是线性关系，unity内的转换公式为r(1,7-0.7r)模拟)
				float mip_roughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);  
				float3 reflectVec = reflect(-viewDir, i.normal);						//反射
				half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS; //从0-1之间的mip_roughness 换算出用于实际采样的mip层级  UNITY_SPECCUBE_LOD_STEPS 默认是6
				//粗糙度越高采样越模糊  cubemap的采样使用三线性插值，即从两张最近的mipmap层级上各做一次二次线性插值再将结果插值。
				half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip);
				//使用DecodeHDR将颜色从HDR编码下解码
				//最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中
				float3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);
				//在查找表中根据nv和粗菜度进行采样    这里之所以0.99 是因为1的时候 颜色突变
				float2 envBDRF = tex2D(_LUT, float2(lerp(0, 0.99, nv), lerp(0, 0.99, roughness))).rg; // LUT采样
				//菲涅尔计算用的NV不是VH 菲涅尔计算用的粗糙度不是金属度
				float3 Flast = fresnelSchlickRoughness(max(nv, 0.0), F0, roughness);
				float kdLast = (1 - Flast) * (1 - _Metallic);
				//间接光漫反射结果
				float3 iblDiffuseResult = iblDiffuse * kdLast * Albedo;
				//间接光高光结果
				float3 iblSpecularResult = iblSpecular * (Flast * envBDRF.r + envBDRF.g) * 2 ;
				//间接光结果
				float3 IndirectResult = iblDiffuseResult + iblSpecularResult;
				float4 result = float4(DirectLightResult + IndirectResult, 1);
				return result;
			}

			ENDCG
		}
	}
}