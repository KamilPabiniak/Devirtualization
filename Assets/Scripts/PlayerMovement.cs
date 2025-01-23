using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    public float speed = 5f;
    public float jumpForce = 5f;
    public CharacterController controller;

    private Vector3 velocity;
    private bool isGrounded;
    public float gravity = -9.81f;
    
    [SerializeField] private Transform cameraTransform;
    [SerializeField] private Transform orientationTransform;
    // For smoothing movement
    private Vector3 currentMoveDirection;
    private Vector3 moveVelocity;
    public float smoothTime = 0.1f; // Adjust for how quickly you want to stop

    void Start()
    {
        // Lock and hide the cursor
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;

        if (controller == null)
        {
            controller = GetComponent<CharacterController>();
        }
    }

    void Update()
    {
        // Sync the orientation object with the camera's horizontal rotation
        Vector3 cameraEulerAngles = cameraTransform.eulerAngles;
        orientationTransform.rotation = Quaternion.Euler(0, cameraEulerAngles.y, 0); // Sync yaw (horizontal rotation)

        // Check if player is grounded
        isGrounded = controller.isGrounded;
        if (isGrounded && velocity.y < 0)
        {
            velocity.y = -2f; // Ensures player stays grounded
        }

        // Get input
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");

        // Use the orientation actor for movement direction
        Vector3 targetMoveDirection = orientationTransform.right * horizontal + orientationTransform.forward * vertical;
        targetMoveDirection.y = 0; // Ensure movement is horizontal
        
        //Original LookDownSlowDown Movement
        //Vector3 targetMoveDirection = cameraTransform.right * horizontal + cameraTransform.forward * vertical;

        // Smoothly transition to the target move direction
        currentMoveDirection = Vector3.SmoothDamp(currentMoveDirection, targetMoveDirection.normalized, ref moveVelocity, smoothTime);

        // Move the player
        controller.Move(currentMoveDirection * speed * Time.deltaTime);

        // Jump logic
        if (Input.GetButtonDown("Jump") && isGrounded)
        {
            velocity.y = Mathf.Sqrt(jumpForce * -2f * gravity);
        }

        // Apply gravity
        velocity.y += gravity * Time.deltaTime;
        controller.Move(velocity * Time.deltaTime);
    }
}
