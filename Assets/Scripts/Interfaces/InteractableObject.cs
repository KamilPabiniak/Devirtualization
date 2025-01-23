using UnityEngine;

public class InteractableObject : MonoBehaviour, IInteractable
{
    public void Interact()
    {
        Debug.Log("You interacted with " + gameObject.name);
        // Add specific interaction logic here (e.g., open a door, pick up an item)
    }
}
