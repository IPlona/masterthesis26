using UnityEngine;

public class FocusBehavior : MonoBehaviour
{
    [Header("Color managment")]
    [SerializeField] ColorManager colorManager;

    [Header("General")]
    [SerializeField] Camera cam;
    [SerializeField] Animator anim; //For later implementation

    [SerializeField] bool canFocus; //In case we want to disable the ability for a bit.

    [SerializeField] bool inFocus;

    private void Update()
    {
        if (Input.GetMouseButtonDown(1) && canFocus && cam)
        {
            //TODO: Implement with animator the smooth transition etc.
            if (!inFocus)
            {
                Debug.Log("Focus M.");
                cam.fieldOfView = 30;

                inFocus = !inFocus;

            } else
            {
                Debug.Log("Goodbye Caroline.");
                cam.fieldOfView = 60;

                inFocus = !inFocus;
            }
        }

        if (inFocus && cam && colorManager && canFocus)
        {
            ShootFocus();
        }
    }

    /// <summary>
    /// This function is called whenever the player is in focus and it casts a raycast.
    /// </summary>
    private void ShootFocus()
    {
        if (Physics.Raycast(cam.transform.position, cam.transform.forward, out RaycastHit hit, 2.5f))
        {
            if (hit.transform.TryGetComponent(out UnlockObjectBehavior uC))
            {
                UnlockedColor[] list;

                //Debug.Log(hit.transform.name);
                list = uC.fillTheMeter(colorManager);

                if (list.Length > 0)
                {
                    Debug.Log("We got colors!");
                    colorManager.addColor(list);
                }
            }
        }
    }
}
