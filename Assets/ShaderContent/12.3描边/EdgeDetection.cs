using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetection : PostEffectBase
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

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (MyMaterial != null)
        {
            MyMaterial.SetFloat("_EdgeOnly",edgeOnly);
            MyMaterial.SetColor("_EdgeColor",edgeColor);
            MyMaterial.SetColor("_BackgroundColor",backgroundColor);
            
            Graphics.Blit(src,dest,MyMaterial);   //调用该方法  shader中必须有个_MainTex 参数
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
