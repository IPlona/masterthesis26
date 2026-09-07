using System;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class SpectrumMask
{
    //



    public Texture2D BuildMask(List<UnlockedColor> colorsList)
    {
                            //For now let's just use the hard coded 360.
        int w = 360;        //width
        Texture2D texture = new Texture2D(w, 3, TextureFormat.ARGB32, false, true);
        texture.filterMode = FilterMode.Point;
        texture.wrapMode = TextureWrapMode.Clamp;

                                                    //Duplicate the list for easier handling.
        List<UnlockedColor> colors = new List<UnlockedColor>(colorsList);   //Hue Layer 0
                                                    //Sort it based on the "minHue".
        colors.Sort(delegate (UnlockedColor x, UnlockedColor y) { return x.minHue.CompareTo(y.minHue); });

        //We need to seperate the different mask
        List<UnlockedColor> vColors = new List<UnlockedColor>();            //Value Layer 1
        List<UnlockedColor> sColors = new List<UnlockedColor>();            //Saturation Layer 2

        for (int j = 0; j < colors.Count; j++)
        {
            switch (colors[j].maskLayer)
            {   //We don't need case 0
                case 1:
                    vColors.Add(colors[j]);
                    colors.RemoveAt(j);
                    j--;
                    break;
                case 2:
                    sColors.Add(colors[j]);
                    colors.RemoveAt(j);
                    j--;
                    break;
            }
        }


        Debug.Log("Color count " + colors.Count);
        //Debug.Log("vColor count " + vColors.Count);
        //Debug.Log("sColor count " + sColors.Count);

        Color[][] colorRange = new Color[3][];
        colorRange[0] = new Color[w];   //hue
        colorRange[1] = new Color[w];   //value
        colorRange[2] = new Color[w];   //sat

        for (int i = 0; i < colorRange[0].Length; i++) //Loop which goes through each pixel.
        {
            colorRange[0][i] = Color.white;
            colorRange[1][i] = Color.white;
            colorRange[2][i] = Color.white;

            if (colors.Count > 0)
            {
                if (colors[0].minHue <= i && colors[0].maxHue >= i) {
                    colorRange[0][i] = Color.black;
                }
                //Delete obsolute color from the list, we won't need it anymore.
                else if (colors[0].maxHue < i) {
                    colors.RemoveAt(0);
                    i--;
                }

                // We can ASSUME that if a color is not unlocked in base-list,
                //it's not gonna be in value or saturation mask either.
                
                //Layer 1
                if (vColors.Count > 0 && vColors[0].minHue <= i && vColors[0].maxHue >= i)
                {
                    colorRange[1][i] = Color.black;
                }
                else if (vColors.Count > 0 && vColors[0].maxHue < i)
                {
                    vColors.RemoveAt(0);
                }
                //Layer 2
                if (sColors.Count > 0 && sColors[0].minHue <= i && sColors[0].maxHue >= i)
                {
                    colorRange[2][i] = Color.black;
                }
                else if (sColors.Count > 0 && sColors[0].maxHue < i)
                {
                    sColors.RemoveAt(0);
                    //i--;
                }
            }

        }

        texture.SetPixels(0, 0, w, 1, colorRange[0]);          //Set pixels according the colorRange data
        texture.SetPixels(0, 1, w, 1, colorRange[1]);          //Layer 0 = Hue, 1 = Value, 2 = Saturation
        texture.SetPixels(0, 2, w, 1, colorRange[2]);          
        texture.Apply();                                       //Apply, this is important so the thing actually works.

        return texture;
    }

}
