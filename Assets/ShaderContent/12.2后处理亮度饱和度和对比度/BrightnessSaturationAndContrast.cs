using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BrightnessSaturationAndContrast : PostEffectBase
{
    public Shader briSatConShader;

    private Material briSatConMaterial;
    public Material MyMaterial
    {
        get
        {
            briSatConMaterial = checkShaderAndCreatMaterial(briSatConShader, briSatConMaterial);
            return briSatConMaterial;
        }
    }
    
    [Range(0.0f,3.0f)]
    public float brightness = 1.0f;
    [Range(0.0f,3.0f)]
    public float saturation = 1.0f;
    [Range(0.0f,3.0f)]
    public float contrast = 1.0f;
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Debug.Log("OnRenderImage0");
        if (MyMaterial != null)
        {
            Debug.Log("OnRenderImage");
            MyMaterial.SetFloat("_Brightness",brightness);
            MyMaterial.SetFloat("_Saturation",saturation);
            MyMaterial.SetFloat("_Contrast",contrast);
            Graphics.Blit(src,dest,MyMaterial);   //调用该方法  shader中必须有个_MainTex 参数
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
    
    
}
