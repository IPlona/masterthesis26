using System.Collections.Generic;
using System.Linq;
using UnityEngine;


[CreateAssetMenu(fileName = "ColorSO", menuName = "ScriptableObjects/ColorsSO")]
public class ColorsSO : ScriptableObject
{

    [SerializeField] Texture2D texMask;

    [SerializeField] List<UnlockedColor> uC = new List<UnlockedColor>();
    [SerializeField] SpectrumMask sM = new SpectrumMask();



    public void refreshMask(string maskName = "_SpectriMask")
    {
        texMask = sM.BuildMask(uC);
        Shader.SetGlobalTexture(maskName, texMask);
    }

    public void addColor(UnlockedColor newColor)
    {
        uC.Add(newColor);

        refreshMask("_SpectriMask");
    }
    public void addColors(UnlockedColor[] newColors)
    {
        for (int i = 0; i < newColors.Length; i++)
        {
            uC.Add(newColors[i]);
        }
        refreshMask("_SpectriMask");
    }

    public void filterDuplicates()
    {
        //This SHOULD filter all the dublicate values from uC
        uC = uC.GroupBy(x => new { x.maskLayer, x.minHue, x.maxHue }).Select(x => x.FirstOrDefault()).ToList();
    }

    public void clearColors()
    {
        uC.Clear();

        refreshMask("_SpectriMask");
    }



    /// <summary>
    /// Simple function which returns a bool if one color in a list is visible.
    /// </summary>
    /// <param name="colors">List of UnlockedColors which will be checked against.</param>
    /// <returns>True if color is visible currently, false if the color is not visible currently.</returns>
    public bool isColorsIn(UnlockedColor[] colors)
    {
        //TODO: simple calculation if the one of the colors is visible.
        //Use colorSO

        for (int i = 0; i < colors.Length; i++)
        {
            int pixelPlacement = (colors[i].maxHue + colors[i].minHue) / 2;

            Color pixelColor = texMask.GetPixel(pixelPlacement, colors[i].maskLayer);
            float colorAverage = (pixelColor.r + pixelColor.g + pixelColor.b) / 3;

            if (colorAverage <= 0)
            {
                return true;
            }

        }
        return false;
    }
}
