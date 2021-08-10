using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostEffectBase
{
    public Shader gaussianBlurShader;

    private Material gaussianBlurMaterial = null;
    public Material MyMaterial
    {
        get
        {
            gaussianBlurMaterial = checkShaderAndCreatMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }
    
    [Range(0,4)]
    public int iterations =3;

    [Range(0.2f,3.0f)]
    public float blurSpread = 0.6f;

    [Range(1,8)]
    public int downSample = 2;


    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (MyMaterial != null)
        {
            //方法1
            // int rtW = src.width;
            // int rtH = src.height;
            // //该函数 分配一块与屏幕大小一致的缓冲区
            // //高斯模糊需要调用2个PASS
            // //所以先要使用 中间缓存获得第一个PASS的结果
            // RenderTexture buff = RenderTexture.GetTemporary(rtW,rtH,0);
            // //所以先要使用 中间缓存获得第一个PASS的结果
            // Graphics.Blit(src,buff,MyMaterial,0);
            // //使用第二个pass对结果再次处理
            // Graphics.Blit(buff,dest,MyMaterial,1);
            // //释放缓存
            // RenderTexture.ReleaseTemporary(buff);
            
            //方法2
            //使用了原屏幕分辨率大小 将临时渲染纹理改为双线性   对图像采样的时候减少需要处理的像素个数提高性能
            // int rtW = src.width/downSample;
            // int rtH = src.height/downSample;
            // //该函数 分配一块与屏幕大小一致的缓冲区
            // //高斯模糊需要调用2个PASS
            // //所以先要使用 中间缓存获得第一个PASS的结果
            // RenderTexture buff = RenderTexture.GetTemporary(rtW,rtH,0);
            // buff.filterMode = FilterMode.Bilinear;
            // //所以先要使用 中间缓存获得第一个PASS的结果
            // Graphics.Blit(src,buff,MyMaterial,0);
            // //使用第二个pass对结果再次处理
            // Graphics.Blit(buff,dest,MyMaterial,1);
            // //释放缓存
            // RenderTexture.ReleaseTemporary(buff);
            
            //方法3  考虑高斯模糊的迭代次数
            int rtW = src.width/downSample;
            int rtH = src.height/downSample;
            //该函数 分配一块与屏幕大小一致的缓冲区
            //高斯模糊需要调用2个PASS
            //所以先要使用 中间缓存获得第一个PASS的结果
            RenderTexture buff0 = RenderTexture.GetTemporary(rtW,rtH,0);
            buff0.filterMode = FilterMode.Bilinear;
            
            Graphics.Blit(src,buff0);

            for (int i = 0; i < iterations; i++)
            {
                MyMaterial.SetFloat("_BlurSize",1.0f + i * blurSpread);

                RenderTexture buff1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                Graphics.Blit(buff0,buff1,MyMaterial,0);
                RenderTexture.ReleaseTemporary(buff0);
                buff0 = buff1;

                buff1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buff0,buff1,MyMaterial,1);
                RenderTexture.ReleaseTemporary(buff0);
                buff0 = buff1;
            }
            Graphics.Blit(buff0,dest);
            RenderTexture.ReleaseTemporary(buff0);
        }
        else 
            Graphics.Blit(src,dest);
    }
}
