using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RoomShadeController : MonoBehaviour
{
    [SerializeField] private float limit;
    [SerializeField] private float posZ;
    [SerializeField] private float offset;

    [SerializeField] private Material shader;


    private void Start()
    {
        limit = shader.GetFloat("_Mask2");

    }

    private void Update()
    {
        posZ = transform.position.z / 10f;
        if (posZ >= -limit && posZ <= limit)
        {
            Debug.Log("Working");
            shader.SetFloat("_Mask1", posZ + offset);
        }
        
    }
}
