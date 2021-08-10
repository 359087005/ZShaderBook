using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectBase
{
    public Shader bloomShader;

    private Material bloomMaterial = null;
    public Material MyMaterial
    {
        get
        {
            bloomMaterial = checkShaderAndCreatMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }
    
        //迭代次数
        [Range(0,4)]
        public int iterations =3;
        //模糊范围
        [Range(0.2f,3.0f)]
        public float blurSpread = 0.6f;
        //缩放系数
        [Range(1,8)]
        public int downSample = 2;//越大 需要处理像素越少  图稿模糊程度 但会变成马赛克
        //较亮区域 阈值
        [Range(0.0f,4.0f)]   //大部分情况 亮度值不会超过1    但是开启HDR 硬件允许我们存储一个更高精度    
        public float luminanceThreshold = 0.6f;

        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (MyMaterial != null)
            {
                MyMaterial.SetFloat("_LuminanceThreshold", luminanceThreshold);

                //方法3  考虑高斯模糊的迭代次数
                int rtW = src.width / downSample;
                int rtH = src.height / downSample;
                //获得一个临时渲染的纹理
                RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
                buffer0.filterMode = FilterMode.Bilinear;
                //使用第一个pass 提取图像中较亮的部分  并存储在buff0里
                Graphics.Blit(src, buffer0, MyMaterial, 0);

                for (int i = 0; i < iterations; i++)
                {
                    //设置材质球模糊值
                    MyMaterial.SetFloat("_Blursize", 1.0f + i * blurSpread);
                    //申请一个临时渲染纹理
                    RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                    //把0 给 1   0就空了   执行第2个pass
                    Graphics.Blit(buffer0, buffer1, MyMaterial, 1);
                    //释放0
                    RenderTexture.ReleaseTemporary(buffer0);
                    //把1在给0
                    buffer0 = buffer1;
                    //重新申请 1
                    buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                    //把0 在给1    执行第3个pass
                    Graphics.Blit(buffer0, buffer1, MyMaterial, 2);
                    //释放0
                    RenderTexture.ReleaseTemporary(buffer0);
                    //在把1给0
                    buffer0 = buffer1;
                }
                //模糊后的较亮区域 存储在buff0 里   将他传递给材质 Bloom
                MyMaterial.SetTexture("_Bloom", buffer0);
                //执行第4个pass   终极混合  并存储在目标中
                Graphics.Blit(src, dest, MyMaterial, 3);

                RenderTexture.ReleaseTemporary(buffer0);
            }
            else
                Graphics.Blit(src, dest);

        }
}
