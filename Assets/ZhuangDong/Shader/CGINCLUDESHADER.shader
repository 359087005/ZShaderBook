// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"MJ/Test"
{
    Properties
    {
        _MainTex("Main Texture", 2D) ="white"
    }
    CGINCLUDE
    #include"UnityCG.cginc"
    sampler2D _MainTex;
    struct vertex_data
    {
        float4 vertex : POSITION;
        float4 texcoord : TEXCOORD0;
    };
    struct v2f
    {
        float4 position : SV_POSITION;
        float2 uv : TEXCOORD0;
    };
    v2f vert1(vertex_data v)
    {
        v2f o;
        o.position =UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord;
        return o;
    }

    v2f vert2(vertex_data v)
    {
        v2f o;
        o.position =UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord;
        return o;
    }
    float4 frag1(v2f i) : COLOR
    {
        return float4(1,0,0,1);
    }
    float4 frag2(v2f i) : COLOR
    {
        return float4(0,1,0,1);
    }
ENDCG
Subshader
{
    pass
    {
        Tags{"Queue"="Transparent"}
        CGPROGRAM
        #pragma vertex vert1
        #pragma fragment frag1
        ENDCG
    }
    pass
    {
        Tags{"Queue"="Transparent"}
        blend srcalpha oneminussrcalpha
        CGPROGRAM
        #pragma vertex vert2
        #pragma fragment frag2
        ENDCG
    }
}
}