using System.Collections;
using UnityEngine;

public class ShaderController : MonoBehaviour
{
    public Material material;

    private float savedWireThickness;
    private Color savedWireTint;

    void Start()
    {
        if (material == null)
        {
            Debug.LogError("Material is not assigned!");
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

        yield return new WaitForSeconds(2.0f);

        // Zapisanie i zmiana _WireThickness i _WireTint
        savedWireThickness = material.GetFloat("_WireThickness");
        savedWireTint = material.GetColor("_WireTint");

        material.SetFloat("_WireThickness", 0.0f);
        material.SetColor("_WireTint", Color.black);

        yield return new WaitForSeconds(1.0f);

        // Przywrócenie zapisu
        material.SetFloat("_WireThickness", savedWireThickness);
        material.SetColor("_WireTint", savedWireTint);

        yield return new WaitForSeconds(1.0f);

        // Znów ustawienie na 0 i czarny
        material.SetFloat("_WireThickness", 0.0f);
        material.SetColor("_WireTint", Color.black);
    }

    void RestoreSettings()
    {
        material.SetFloat("_Transition", 1.0f);
        material.SetFloat("_WireThickness", savedWireThickness);
        material.SetColor("_WireTint", savedWireTint);
    }
}
