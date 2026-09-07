using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;

public class ColorManager : MonoBehaviour
{
    //This is the manager script which feeds data to the the shader etc etc.

    [SerializeField] ColorsSO ColorsSO;



    void Start()
    {
        //Init
        ColorsSO.refreshMask("_SpectriMask");
    }

    // Update is called once per frame
    void Update()
    {
        //DEBUGGER
        if (Input.GetKeyDown("1")) {
            //Red
            UnlockedColor[] reds = { new UnlockedColor(0, 18, 0, "Red"), new UnlockedColor(346, 360, 0, "Red") };
            addColor(reds);
        }
        if (Input.GetKeyDown("2"))
        {
            //Orange
            addColor(new UnlockedColor(18, 45, 0, "Orange"));
        }
        if (Input.GetKeyDown("3"))
        {
            //Yellow
            addColor(new UnlockedColor(46, 68, 0, "Yellow"));
        }
        if (Input.GetKeyDown("4"))
        {
            //Green
            addColor(new UnlockedColor(69, 100, 0, "Lime"));
            addColor(new UnlockedColor(101, 135, 0, "Green"));
        }
        if (Input.GetKeyDown("5"))
        {
            addColor(new UnlockedColor(136, 170, 0, "Turqois"));
            addColor(new UnlockedColor(171, 205, 0, "Cyan"));
        }
        if (Input.GetKeyDown("6"))
        {
            //Blue
            addColor(new UnlockedColor(206, 252, 0, "Blue"));
        }
        if (Input.GetKeyDown("7"))
        {
            addColor(new UnlockedColor(253, 290, 0, "Violet"));
            addColor(new UnlockedColor(291, 345, 0, "Magenta"));
        }
        if (Input.GetKeyDown("8"))
        {
            addColor(new UnlockedColor(0, 360, 1, "Lot of hue"));
            addColor(new UnlockedColor(0, 360, 2, "Lot of hue"));
        }


        if (Input.GetKeyDown("9"))
        {
            //Remove dublicates
            filterDuplicates();
            ColorsSO.refreshMask("_SpectriMask");
        }
        if (Input.GetKeyDown("0"))
        {
            //Clear
            clearColors();
        }
    }


    public void addColor(UnlockedColor newColor)
    {
        ColorsSO.addColor(newColor);
    }
    public void addColor(UnlockedColor[] newColors)
    {
        ColorsSO.addColors(newColors);
    }

    public void filterDuplicates()
    {
        ColorsSO.filterDuplicates();
    }

    public void clearColors()
    {
        ColorsSO.clearColors();
    }



    /// <summary>
    /// Simple function which returns a bool if one color in a list is visible.
    /// This function delegates the calculation to ColorsSO
    /// </summary>
    /// <param name="colors">List of UnlockedColors which will be checked against.</param>
    /// <returns>True if color is visible currently, false if the color is not visible currently.</returns>
    public bool isColorsIn(UnlockedColor[] colors)
    {
        return ColorsSO.isColorsIn(colors);
    }

}
