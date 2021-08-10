using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffectBase : MonoBehaviour
{
   void Start()
    {
        ChecResources();
    }

    protected Material checkShaderAndCreatMaterial(Shader shader,Material material)
    {
        if (shader == null)
            return null;

        if (shader.isSupported && material && material.shader == shader)
        {
            return material;
        }

        
        if (!shader.isSupported)
            return null;
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material)
            {
                Debug.Log("isSupported2");
                return material;
            }
            else
            {
                Debug.Log("isSupported3");
                return null;
            }
        }
    }

    protected void ChecResources()
    {
        bool isSupported = CheckSupport();

        if (!isSupported)
        {
            NotSupported();
        }
    }

    protected bool CheckSupport()
    {
        if (!SystemInfo.supportsImageEffects || !SystemInfo.supports3DRenderTextures)
        {
            return false;
        }
        return true;
    }

    protected void NotSupported()
    {
        enabled = false;
    }
}
