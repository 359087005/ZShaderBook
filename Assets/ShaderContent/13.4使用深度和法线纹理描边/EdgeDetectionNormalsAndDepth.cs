using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetectionNormalsAndDepth : PostEffectBase
{
    public Shader edgeDetectionShader;

    private Material edgeDetectionMaterial = null;
    public Material MyMaterial
    {
        get
        {
            edgeDetectionMaterial = checkShaderAndCreatMaterial(edgeDetectionShader, edgeDetectionMaterial);
            return edgeDetectionMaterial;
        }
    }

    [Range(0.0f,1f)]
    public float edgeOnly; //边缘线强度
    public Color edgeColor = Color.black;//描边颜色
    public Color backgroundColor = Color.white;//背景颜色
    public float sampleDistance = 1.0f; //控制对深度和法线纹理采样时  使用的采样距离   值越大 描边越宽
    //这两个值 影响当邻域的深度值和法线值相差多少时 会被认为存在一条便捷
    public float sensitivityDepth = 1.0f; //
    public float sensitivityNormals = 1.0f; //

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    //默认是在透明和不透明 pass之后调用
    //特性在执行 完 不透明的PSS之后 执行 该函数
    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (MyMaterial != null)
        {
            MyMaterial.SetFloat("_EdgeOnly",edgeOnly);
            MyMaterial.SetColor("_EdgeColor",edgeColor);
            MyMaterial.SetColor("_BackgroundColor",backgroundColor);
            MyMaterial.SetFloat("_SampleDistance", sampleDistance);
            MyMaterial.SetVector("_Sensitivity",new Vector4(sensitivityNormals,sensitivityDepth,0,0));
            Graphics.Blit(src,dest,MyMaterial);   //调用该方法  shader中必须有个_MainTex 参数
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
