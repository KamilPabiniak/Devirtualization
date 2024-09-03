using UnityEngine;

public class ParticleSync : MonoBehaviour
{
    public Material devirtualizationMaterial; // Materiał używany przez shader "Devirtualization"
    public ParticleSystem particleSystem; // System cząsteczek, który ma być zsynchronizowany
    public Camera maskCamera; // Kamera renderująca maskę na RenderTexture
    public RenderTexture maskRenderTexture; // RenderTexture, na którym przechwytywana jest maska

    private Texture2D maskTexture2D; // Tekstura do odczytu wartości maski
    private Color[] maskColors; // Tablica do przechowywania wartości maski
    private ParticleSystem.EmitParams emitParams = new ParticleSystem.EmitParams(); // Parametry emisji cząsteczek

    void Start()
    {
        // Tworzymy teksturę do przechowywania danych maski
        maskTexture2D = new Texture2D(maskRenderTexture.width, maskRenderTexture.height, TextureFormat.RGBA32, false);

        // Ustawiamy kamerę do renderowania maski na RenderTexture
        if (maskCamera != null)
        {
            maskCamera.targetTexture = maskRenderTexture;
        }
    }

    void Update()
    {
        // Przechwytujemy dane z RenderTexture i zapisujemy je w maskTexture2D
        RenderTexture.active = maskRenderTexture;
        maskTexture2D.ReadPixels(new Rect(0, 0, maskRenderTexture.width, maskRenderTexture.height), 0, 0);
        maskTexture2D.Apply();
        RenderTexture.active = null;

        // Pobieramy wszystkie kolory z maskTexture2D
        maskColors = maskTexture2D.GetPixels();

        // Iterujemy przez piksele maski, aby określić, gdzie emitować cząstki
        for (int i = 0; i < maskColors.Length; i++)
        {
            float particleEmissionMask = maskColors[i].a; // Używamy kanału alpha jako maski emisji cząsteczek

            // Jeśli maska przekracza pewien próg, emitujemy cząstki
            if (particleEmissionMask > 0.1f) // Możesz dostosować próg w zależności od potrzeb
            {
                Vector2 pixelPosition = IndexToPosition(i, maskTexture2D.width);
                Vector3 worldPosition = PixelToWorldPosition(pixelPosition);

                emitParams.position = worldPosition;
                particleSystem.Emit(emitParams, 1); // Emitujemy jedną cząstkę na aktywne miejsce, możesz zmienić ilość emisji
            }
        }
    }

    // Konwertujemy indeks pikseli na pozycję w przestrzeni 2D
    Vector2 IndexToPosition(int index, int width)
    {
        int x = index % width;
        int y = index / width;
        return new Vector2(x, y);
    }

    // Konwertujemy pozycję piksela w przestrzeni 2D na pozycję w przestrzeni 3D świata
    Vector3 PixelToWorldPosition(Vector2 pixelPosition)
    {
        Ray ray = maskCamera.ScreenPointToRay(new Vector3(pixelPosition.x, pixelPosition.y, 0));
        return ray.GetPoint(10); // Możesz dostosować odległość w zależności od potrzeb
    }
}
