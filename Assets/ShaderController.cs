using System;
using System.Collections;
using UnityEngine;

public class ShaderController : MonoBehaviour
{
    public Material material;

    private float _showWireframe;
    private float _showWireTint;

    void Start()
    {
        if (material == null)
        {
            Debug.LogError("Material is not assigned!");
        }
        else
        {
            _showWireframe = material.GetFloat("_ShowWireframe");
            _showWireTint = material.GetFloat("_ShowWireTint");
        }
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Z))
        {
            StartCoroutine(ChangeTransition(1.0f, 0.0f, 1.0f)); // Zmiana z 1 do 0
        }
        else if (Input.GetKeyDown(KeyCode.C))
        {
            StartCoroutine(ChangeTransition(0.0f, 1.0f, 1.0f)); // Zmiana z 0 do 1
        }
        else if (Input.GetKeyDown(KeyCode.Space))
        {
            StopAllCoroutines();
            StartCoroutine(SpaceActionSequence());
        }
        else if (Input.GetKeyDown(KeyCode.R))
        {
            RestoreSettings();
        }
    }

    IEnumerator ChangeTransition(float start, float end, float duration)
    {
        float elapsedTime = 0.0f;

        while (elapsedTime < duration)
        {
            elapsedTime += Time.deltaTime;
            float newTransition = Mathf.Lerp(start, end, elapsedTime / duration);
            material.SetFloat("_Transition", newTransition);
            yield return null;
        }

        material.SetFloat("_Transition", end);
    }

    IEnumerator SpaceActionSequence()
    {
        // Zmiana _Transition z 1 do 0
        StartCoroutine(ChangeTransition(1.0f, 0.0f, 1.0f));

        yield return new WaitForSeconds(1.2f);

        material.SetFloat("_ShowWireframe", 0.0f);
        material.SetFloat("_ShowWireTint", 0.0f);

        yield return new WaitForSeconds(0.05f);

        // Przywrócenie zapisu
        material.SetFloat("_ShowWireframe", _showWireframe);
        material.SetFloat("_ShowWireTint", _showWireTint);

        yield return new WaitForSeconds(0.05f);

        // Znów ustawienie na 0 i czarny
        material.SetFloat("_ShowWireframe", 0.0f);
        material.SetFloat("_ShowWireTint", 0.0f);
    }

    void RestoreSettings()
    {
        material.SetFloat("_Transition", 1.0f);
        material.SetFloat("_ShowWireframe", _showWireframe);
        material.SetFloat("_ShowWireTint", _showWireTint);
    }

    private void OnDisable()
    {
        RestoreSettings();
    }
}
