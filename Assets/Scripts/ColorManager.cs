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
            UnlockedColor[] reds = { new UnlockedColor(0, 18, 0, "Red"), new UnlockedColor(350, 360, 0, "Red") };
            addColor(reds);
        }
        if (Input.GetKeyDown("2"))
        {
            //Orange
            addColor(new UnlockedColor(18, 46, 0, "Orange"));
        }
        if (Input.GetKeyDown("3"))
        {
            //Yellow
            addColor(new UnlockedColor(46, 68, 0, "Yellow"));
        }
        if (Input.GetKeyDown("4"))
        {
            //Green
            addColor(new UnlockedColor(68, 160, 0, "Green"));
        }
        if (Input.GetKeyDown("5"))
        {
            //Blue, technically blue should be in 2, Cyan and Blue... Well.
            addColor(new UnlockedColor(160, 255, 0, "Blue"));
        }
        if (Input.GetKeyDown("6"))
        {
            //Violet/Purple
            addColor(new UnlockedColor(255, 300, 0, "Violet"));
        }
        if (Input.GetKeyDown("7"))
        {
            //Magenta
            addColor(new UnlockedColor(300, 350, 0, "Magenta"));
        }
        if (Input.GetKeyDown("8"))
        {
            //Magenta
            //addColor(new UnlockedColor(0, 360, 1, "Lot of hue"));
            //addColor(new UnlockedColor(0, 360, 2, "Lot of hue"));
            ColorsSO.refreshMask("_SpectriMask");
        }


        if (Input.GetKeyDown("9"))
        {
            //Remove dublicates
            filterDuplicates();
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
