using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectBase
{
    public Shader Motionhader;

    private Material motionMaterial = null;
    public Material MyMaterial
    {
        get
        {
            motionMaterial = checkShaderAndCreatMaterial(Motionhader, motionMaterial);
            return motionMaterial;
        }
    }

    //值越大，运动拖尾效果越明显 防止拖尾效果完全替代当前帧渲染 所以最大到0.9
    [Range(0.0f, 0.9f)] public float blurAmount = 0.5f;


    private RenderTexture accmulationTexture;

    private void OnDisable()
    {
        Destroy(accmulationTexture);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (MyMaterial != null)
        {
            if (accmulationTexture == null || accmulationTexture.width != src.width ||
                accmulationTexture.height != src.height)
            {
                DestroyImmediate(accmulationTexture);
                accmulationTexture = new RenderTexture(src.width, src.height, 0);
                accmulationTexture.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(src,accmulationTexture); //对混合图像进行初始化
            }
            accmulationTexture.MarkRestoreExpected();  //需要进行一个渲染纹理的恢复操作    恢复操作发生在渲染到纹理而该纹理又没有被提前清空或销毁的情况
            
            MyMaterial.SetFloat("_BlurAmount",1-blurAmount);
            
            Graphics.Blit(src,accmulationTexture,MyMaterial);
            
            Graphics.Blit(accmulationTexture,dest);
        }
        else 
            Graphics.Blit(src,dest);
    }
}
