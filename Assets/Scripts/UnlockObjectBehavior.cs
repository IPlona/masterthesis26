using UnityEngine;

public class UnlockObjectBehavior : MonoBehaviour
{
    [SerializeField] bool isReleased;   //If the object colors have already been added.
    [SerializeField] bool canFill;      //Condition bool, based on what colors are unlocked.
    [SerializeField] bool canCheck;     //

    [SerializeField] float meter;       //This works as simplified timer
    [SerializeField] float maxMeter;    //When the colors "release" / unlocks from this object

    [SerializeField] float waitMeter = 0;   //Simple timer to wait out when a new check to the canFill should be done
    [SerializeField] float maxWait = 500;   
                                            //TODO: Later when debugging is over we can hide these from SerializeField.

    [Header("Colors")]
        //These are the colors which will be given when this object is "unlocked", aka. the meter is full.
        //+ In order for the meter to fill when looked at, one of the colors listed here needs to be unlocked.
    [SerializeField] UnlockedColor[] ownColors;

    private void FixedUpdate()
    {
        if (canCheck)
        {   
            waitMeter++;

            if (waitMeter > maxWait)
            {
                canCheck = false;
            }
        }
    }

    public UnlockedColor[] fillTheMeter(ColorManager cm)
    {
        if (!isReleased)
        {
            waitMeter = 0;

            if (!canCheck)
            {
                canCheck = true;
                //Recalculate canFill
                canFill = cm.isColorsIn(ownColors);

                //TODO: Decide if this is a good choice or if we need to do it else where.
                meter = 0;
            }

            if (canFill) //Placeholder for the condition system
            {
                meter++;

                if (meter > maxMeter) {
                    canFill = false; //Turn itself off firstly.
                    isReleased = true;
                    //Release colors -> We return ownColors to FocusBehavior where they are delegated to ColorManager
                    return ownColors;
                }
            }
        }
        return new UnlockedColor[0];
    }


    public bool getCanFill()
    {
        return canFill;
    }
    public float getMeter()
    {
        return meter;
    }
    public float getMaxMeter()
    {
        return maxMeter;
    }
}
