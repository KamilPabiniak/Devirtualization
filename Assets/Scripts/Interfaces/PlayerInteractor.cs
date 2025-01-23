using UnityEngine;

public class PlayerInteractor : MonoBehaviour
{
    public float interactionRange = 2f; // Interaction range

    [SerializeField]
    private LayerMask interactableLayer; // Layer for interactable objects

    private Camera playerCamera;

    private void Start()
    {
        playerCamera = Camera.main;
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.E)) // Press 'E' to interact
        {
            AttemptInteraction();
        }
    }

    private void AttemptInteraction()
    {
        // Perform the raycast
        Ray ray = new Ray(playerCamera.transform.position, playerCamera.transform.forward);
        RaycastHit hit;

        // Visualize the ray in the Scene view
        Debug.DrawRay(playerCamera.transform.position, playerCamera.transform.forward * interactionRange, Color.red);

        if (Physics.Raycast(ray, out hit, interactionRange, interactableLayer))
        {
            IInteractable interactable = hit.collider.GetComponent<IInteractable>();

            if (interactable != null)
            {
                interactable.Interact();
            }
        }
    }
}
