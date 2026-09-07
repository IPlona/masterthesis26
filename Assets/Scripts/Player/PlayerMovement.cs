using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    //Credit for the base code: https://www.youtube.com/watch?v=f473C43s8nE


    [SerializeField] bool canMove;

    [Header("General")]
    [SerializeField] float sens;
    [SerializeField] float speed;
    float usageSpeed;
    [SerializeField] float sprintSpeed;

    [Header("Looking")]
    //Neck is the vertical rotation of the camera
    [SerializeField] Transform neck;

    private float xRot;
    [SerializeField] Vector2 xRotClamp;
    private float yRot;

    [Header("Moving")]
    [SerializeField] Transform ori; //This might be the same as neck

    float horizontalInput;
    float verticalInput;
    Vector3 direction;

    Rigidbody rb;
    
    //Implement jumping if that's needed.


    private void Start()
    {
        //Manage this elsewhere TODO
        Cursor.lockState = CursorLockMode.Locked;
        //Cursor.visible = false;

        rb = GetComponent<Rigidbody>();
        rb.freezeRotation = true;   //TODO: Unneeded?

        //Set speed
        usageSpeed = speed;

    }


    // Update is called once per frame
    void Update()
    {
        if (canMove)
        {
            //Look around
            float mouseX = Input.GetAxisRaw("Mouse X") * Time.deltaTime * sens;
            float mouseY = Input.GetAxisRaw("Mouse Y") * Time.deltaTime * sens;

            yRot += mouseX;
            xRot -= mouseY;
            xRot = Mathf.Clamp(xRot, xRotClamp.x, xRotClamp.y);

            ori.rotation = Quaternion.Euler(0, yRot, 0);  //Rotate the general orientation
            neck.rotation = Quaternion.Euler(xRot, yRot, 0);    //Rotate the vertical orientation

            //Movement
            InputTaken();
        }
    }

    private void FixedUpdate()
    {
        MovePlayer();
    }

    private void InputTaken()
    {
        horizontalInput = Input.GetAxisRaw("Horizontal");
        verticalInput = Input.GetAxisRaw("Vertical");
    }

    private void MovePlayer()
    {
        direction = ori.forward * verticalInput + ori.right * horizontalInput;

        rb.AddForce(direction.normalized * usageSpeed * 10f, ForceMode.Force);
    }
}
