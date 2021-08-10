using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectBase
{
    public Shader MotionBlurWithDepthTextureShader;

    private Material MotionBlurWithDepthTextureMaterial = null;

    public Material MyMaterial
    {
        get
        {
            MotionBlurWithDepthTextureMaterial = checkShaderAndCreatMaterial(MotionBlurWithDepthTextureShader,
                MotionBlurWithDepthTextureMaterial);
            return MotionBlurWithDepthTextureMaterial;
        }
    }

    //运动模糊时模糊图像使用的大小
    [Range(0.0f, 1.0f)] public float blurSize = 0.5f;

    private Camera myCamera;
    public Camera MyCamera 
    {
        get
        {
            if(myCamera==null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    private Matrix4x4 previousViewProjectionMatrix;

    private void OnEnable()
    {
        myCamera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (MyMaterial != null)
        {
            MyMaterial.SetFloat("_BlurSize",blurSize);
            //计算和传递运动模糊使用的各个属性
            
            MyMaterial.SetMatrix("_PreviousViewProjectionMatrix",previousViewProjectionMatrix);
            //两个变换矩阵   前一帧的视角* 投影矩阵  
            //myCamera.projectionMatrix 当前摄像机的投影矩阵
            //myCamera.worldToCameraMatrix; 当前摄像机的视角矩阵
            Matrix4x4 currenViewProjectionMatrix = MyCamera.projectionMatrix * MyCamera.worldToCameraMatrix;
            //当前帧的视角* 投影矩阵的逆矩阵  上面的结果取逆
            Matrix4x4 currentViewProjectionInverseMatrix = currenViewProjectionMatrix.inverse;
            MyMaterial.SetMatrix("_CurrentViewProjectionInverseMatrix",currentViewProjectionInverseMatrix);
            previousViewProjectionMatrix = currenViewProjectionMatrix;
            Graphics.Blit(src,dest,MyMaterial);
        }
        else 
            Graphics.Blit(src,dest);
    }
}

