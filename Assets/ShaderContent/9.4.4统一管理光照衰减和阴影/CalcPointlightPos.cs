using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CalcPointlightPos : MonoBehaviour
{
    public Vector3 pointoffset;
     Vector3 pointLightPos;
    
    private Material mat;
    private void OnEnable()
    {
        pointLightPos = this.transform.position + pointoffset;

        mat = this.GetComponent<Renderer>().sharedMaterials[0];
        
        mat.SetVector("_PointLightPos",pointLightPos);
    }

    private void Update()
    {
        pointLightPos = this.transform.position + pointoffset;
        //pointLightPos.z *= -1;
        mat.SetVector("_PointLightPos",pointLightPos);
    }
}
