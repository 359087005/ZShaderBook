using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithDepthTexture : PostEffectBase
{
    public Shader FogWithDepthTextureShader;

    private Material FogWithDepthTextureMaterial = null;

    public Material MyMaterial
    {
        get
        {
            FogWithDepthTextureMaterial = checkShaderAndCreatMaterial(FogWithDepthTextureShader,
                FogWithDepthTextureMaterial);
            return FogWithDepthTextureMaterial;
        }
    }

    //获取摄像机的相关参数  近才裁剪平面的距离  FOV  需要获取摄像机在世界空间的 方向
    private Camera myCamera;
    public Camera MyCamera
    {
        get
        {
            if (myCamera == null)
                myCamera = this.GetComponent<Camera>();
            return myCamera;
        }
    }
    private Transform myCameraTransform;
    public Transform MyCameraTransform
    {
        get
        {
            if (myCameraTransform == null)
                myCameraTransform = this.GetComponent<Transform>();
            return myCameraTransform;
        }
    }


    [Range(0.0f, 3.0f)] public float fogDensity = 1.0f; //雾的浓度
     
    public Color fogColor = Color.white; //雾的颜色

    public float fogStart = 0.0f;//雾的起始高度
    public float fogEnd = 2.0f;//雾的终止高度

    private void OnEnable()
    {
        //获取摄像机的深度纹理
        myCamera.depthTextureMode |= DepthTextureMode.Depth;
    }


    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(MyMaterial!= null)
        {
            Matrix4x4 frustumCorners;
            frustumCorners = Matrix4x4.identity;
       

        float fov = MyCamera.fieldOfView;
        float near = MyCamera.nearClipPlane; //近裁剪面
        float far = MyCamera.farClipPlane; //远裁剪面   
        float aspect = MyCamera.aspect;

        float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        Vector3 toRight = MyCameraTransform.right * halfHeight * aspect;
        Vector3 toTop = MyCameraTransform.up * halfHeight;
        Vector3 topLeft = MyCameraTransform.forward * near + toTop - toRight;
        float scale = topLeft.magnitude / near;
        
        topLeft.Normalize();
        topLeft *= scale;

        Vector3 topRight = MyCameraTransform.forward * near + toRight + toTop;
        topRight.Normalize();
        topRight *= scale;

        Vector3 bottomLeft = MyCameraTransform.forward * near - toTop - toRight;
        bottomLeft.Normalize();
        bottomLeft *= scale;

        Vector3 bottomRight = MyCameraTransform.forward * near + toRight - toTop;
        bottomRight .Normalize();
        bottomRight *= scale;

        frustumCorners.SetRow(0,bottomLeft);
        frustumCorners.SetRow(1,bottomRight);
        frustumCorners.SetRow(2,topRight);
        frustumCorners.SetRow(3,topLeft);
        
        MyMaterial.SetMatrix("_FrustumCornersRay",frustumCorners);
        MyMaterial.SetMatrix("_ViewProjectionInverseMatrix",(MyCamera.projectionMatrix *MyCamera.worldToCameraMatrix).inverse);
        
        MyMaterial.SetFloat("_Fogdensity",fogDensity);
        MyMaterial.SetColor("_FogColor",fogColor);
        MyMaterial.SetFloat("_FogStart",fogStart);
        MyMaterial.SetFloat("_FogEnd",fogEnd);
        
        Graphics.Blit(src,dest,MyMaterial);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
