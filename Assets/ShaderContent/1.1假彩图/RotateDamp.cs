using System;
using UnityEngine;
using System.Collections;

//操作方式
public enum ControlTypeTest
{
    mouseControl,
    touchControl,
}

public class RotateDamp : MonoBehaviour
{
    public ControlTypeTest controlType;
    public Transform rotTarget;

    //旋转速度加成系数
    public float rotSpeedScalar=20f;
    private float currentSpeed = 0;
    private void Start()
    {
        float a = float.Parse("-0.1994895");
        Debug.Log(a);
    }

    public float timerCalc = 0.1f;
    private float timer;
    void Update()
    {
        timer += Time.deltaTime *timerCalc;
        if (timer >= 1)
            timer = 1;
       
            //鼠标操作
            if (Input.GetMouseButton(0))
            {
                //拖动时速度
                //鼠标或手指在该帧移动的距离*deltaTime为手指移动的速度,此处为Input.GetAxis("Mouse X") / Time.deltaTime
                //不同帧率下lerp的第三个参数(即混合比例)也应根据帧率而不同--
                //考虑每秒2帧和每秒100帧的情况，如果此参数为固定值，那么在2帧的情况下，一秒后达到目标速度的0.75,而100帧的情况下，一秒后则基本约等于目标速度
                currentSpeed = Mathf.Lerp(currentSpeed, Input.GetAxis("Mouse X") / Time.deltaTime,Time.deltaTime);
            }
            else
            {
                //放开时速度
                currentSpeed = Mathf.Lerp(currentSpeed, 0, 0.5f * Time.deltaTime);
            }
            rotTarget.rotation = Quaternion.Slerp(rotTarget.rotation,
            Quaternion.Euler(rotTarget.eulerAngles - new Vector3(0, Time.deltaTime * currentSpeed * rotSpeedScalar, 0)),
            timer
        );
        //rotTarget.Rotate(Vector3.down, Time.deltaTime * currentSpeed * rotSpeedScalar);
    }
}
