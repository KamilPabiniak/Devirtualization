using UnityEngine;

public class ParticleSync : MonoBehaviour
{
    public ParticleSystem particleSystem;
    public Material material; // Referencja do materiału z Twoim shaderem

    private ParticleSystem.EmissionModule emissionModule;

    void Start()
    {
        emissionModule = particleSystem.emission;
    }

    void Update()
    {
        float transitionValue = material.GetFloat("_Transition");
        emissionModule.rateOverTime = Mathf.Lerp(0, 100, transitionValue); // Emisja wzrasta z postępem maski
    }
}