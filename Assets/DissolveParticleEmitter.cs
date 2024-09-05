using UnityEngine;

public class DissolveParticleController : MonoBehaviour
{
    public Material dissolveMaterial; // Materiał z Twojego shadera
    public ParticleSystem particleSystem; // System cząsteczek
    public Texture2D dissolveMask; // Maska rozpuszczania

    private Mesh mesh;
    private ParticleSystem.EmitParams emitParams;
    private float lastDissolveValue = 0f;

    private Vector3[] vertices;
    private Vector3[] normals;
    private Vector2[] uvs;
    private Color[] dissolveMaskColors;

    void Start()
    {
        mesh = GetComponent<MeshFilter>().mesh;

        // Buforowanie wierzchołków i normalnych
        vertices = mesh.vertices;
        normals = mesh.normals;
        uvs = mesh.uv;

        // Buforowanie maski rozpuszczania
        int maskWidth = dissolveMask.width;
        int maskHeight = dissolveMask.height;
        dissolveMaskColors = new Color[maskWidth * maskHeight];
        for (int i = 0; i < maskWidth; i++)
        {
            for (int j = 0; j < maskHeight; j++)
            {
                dissolveMaskColors[j * maskWidth + i] = dissolveMask.GetPixelBilinear((float)i / maskWidth, (float)j / maskHeight);
            }
        }

        emitParams = new ParticleSystem.EmitParams(); // Inicjalizuj parametry emisji
    }

    void Update()
    {
        float currentDissolveValue = dissolveMaterial.GetFloat("_Transition");

        // Emitowanie cząsteczek tylko wtedy, gdy jest zmiana rozpuszczania
        if (currentDissolveValue < lastDissolveValue)
        {
            EmitParticles();
        }

        lastDissolveValue = currentDissolveValue;
    }

    void EmitParticles()
    {
        // Przeliczenie tylko niektórych wierzchołków (np. co drugi wierzchołek)
        for (int i = 0; i < vertices.Length; i += 2) // Emituj tylko z co drugiego wierzchołka, aby zredukować obciążenie
        {
            Vector3 localPosition = vertices[i];
            Vector3 worldPosition = transform.localToWorldMatrix.MultiplyPoint3x4(localPosition);

            // Korzystanie z buforowanych kolorów maski
            Vector2 uv = uvs[i];
            int uIndex = Mathf.FloorToInt(uv.x * dissolveMask.width);
            int vIndex = Mathf.FloorToInt(uv.y * dissolveMask.height);
            Color maskPixel = dissolveMaskColors[vIndex * dissolveMask.width + uIndex];

            if (maskPixel.r > lastDissolveValue && maskPixel.r <= lastDissolveValue + 0.01f)
            {
                Vector3 localNormal = normals[i];
                Vector3 worldNormal = transform.localToWorldMatrix.MultiplyVector(localNormal);

                EmitParticleAtPosition(worldPosition, worldNormal);
            }
        }
    }

    void EmitParticleAtPosition(Vector3 position, Vector3 normal)
    {
        // Przekształcenie na lokalne współrzędne systemu cząsteczek
        Vector3 localPosition = particleSystem.transform.InverseTransformPoint(position);
        emitParams.position = localPosition;

        // Przekształcenie normalnych na przestrzeń lokalną systemu cząsteczek
        Vector3 localNormal = particleSystem.transform.InverseTransformDirection(normal);
        Quaternion rotation = Quaternion.LookRotation(localNormal);
        emitParams.rotation3D = rotation.eulerAngles;

        // Emituj więcej cząsteczek na raz, aby zredukować liczbę wywołań
        particleSystem.Emit(emitParams, 1); 
    }
}
