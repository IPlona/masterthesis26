using UnityEngine;

[System.Serializable]
public class UnlockedColor
{
    //This is a class for colors which are unlocked. 

    public string colorName;    //For convinience
    public int minHue;          //From range 0-360, where does color's coverage start
    public int maxHue;          //From range 0-360, where does color's coverage end
                                //Initializing makes sure the bigger one is max and smaller min.

    public int maskLayer;       //In which mask this color is unlocked in, aka.
                                // 0  = normal spectrum mask
                                // 1  = value mask -> Dark colors (Brown, etc.)
                                // 2  = saturation mask -> Light colors (Pink, etc.)


    public UnlockedColor(int minH = 0, int maxH = 0, int layer = 0, string cN = "N/A") {
        colorName = cN;

        if (minH < maxH)
        {
            minHue = minH;
            maxHue = maxH;
        } else
        {   //In case user tries to input range which is smaller than should.
            minHue = maxH;
            maxHue = minH;
        }

        maskLayer = layer;

    }

}
