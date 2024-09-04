using UnityEngine;

public class DissolveParticleController : MonoBehaviour
{
    public Material dissolveMaterial; // Materiał z Twojego shadera
    public ParticleSystem particleSystem; // System cząsteczek
    public Texture2D dissolveMask; // Maska rozpuszczania

    private Mesh mesh;
    private ParticleSystem.EmitParams emitParams;
    private float lastDissolveValue = 0f;

    void Start()
    {
        mesh = GetComponent<MeshFilter>().mesh; // Pobierz mesh obiektu
        emitParams = new ParticleSystem.EmitParams(); // Inicjalizuj parametry emisji
    }

    void Update()
    {
        float currentDissolveValue = dissolveMaterial.GetFloat("_Transition");

        if (currentDissolveValue < lastDissolveValue)
        {
            EmitParticles();
        }

        lastDissolveValue = currentDissolveValue;
    }

    void EmitParticles()
    {
        // Przeliczenie wszystkich wierzchołków w meshu
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            Vector3 localPosition = mesh.vertices[i]; // Użyj rzeczywistej pozycji wierzchołka bez normalizacji
            Vector3 worldPosition = transform.TransformPoint(localPosition); // Przekształć lokalną pozycję na światową

            Vector2 uv = mesh.uv[i];
            Color maskPixel = dissolveMask.GetPixelBilinear(uv.x, uv.y);

            if (maskPixel.r > lastDissolveValue && maskPixel.r <= lastDissolveValue + 0.01f)
            {
                Vector3 localNormal = mesh.normals[i]; // Pobierz normalną wierzchołka
                Vector3 worldNormal = transform.TransformDirection(localNormal); // Przekształć normalną do przestrzeni świata

                EmitParticleAtPosition(worldPosition, worldNormal);
            }
        }
    }

    void EmitParticleAtPosition(Vector3 position, Vector3 normal)
    {
        emitParams.position = position; // Ustaw pozycję emisji na światowe współrzędne wierzchołka

        // Ustaw rotację cząsteczki zgodnie z normalną wierzchołka
        Quaternion rotation = Quaternion.LookRotation(normal);
        emitParams.rotation3D = rotation.eulerAngles;

        particleSystem.Emit(emitParams, 1); // Emituj jedną cząsteczkę
    }
}
