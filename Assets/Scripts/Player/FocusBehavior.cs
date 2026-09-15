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
                intoFocus();
            } else
            {
                outofFocus();
            }
        }

        if (inFocus && anim && colorManager && canFocus)
        {
            ShootFocus();
        }
    }

    private void intoFocus()
    {
        Debug.Log("Focus M.");
        //cam.fieldOfView = 30;
        anim.SetTrigger("focus");

        inFocus = !inFocus;
    }
    private void outofFocus(string whichTriggerExit = "outfocus")
    {
        Debug.Log("Goodbye Caroline.");
        //cam.fieldOfView = 60;
        anim.SetTrigger(whichTriggerExit);
        anim.SetBool("focusing", false);
        anim.SetFloat("depth", 0);

        inFocus = !inFocus;
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
                anim.SetBool("focusing", uC.getCanFill());
                list = uC.fillTheMeter(colorManager);

                anim.SetFloat("depth", uC.getMeter() / uC.getMaxMeter());
                anim.SetFloat("startDepth", ((1.0f / Time.deltaTime) / uC.getMaxMeter()) );

                if (list.Length > 0)
                {
                    Debug.Log("We got colors!");
                    colorManager.addColor(list);
                    outofFocus("colorUnlocked");
                }
            }
            else
            {
                anim.SetBool("focusing", false);
            }
        }
        else
        {
            anim.SetBool("focusing", false);
        }
    }

    //These are mostly for the animator calls
    public void canFocusTrue()
    {
        canFocus = true;
    }
    public void canFocusFalse()
    {
        canFocus = false;
    }
}
