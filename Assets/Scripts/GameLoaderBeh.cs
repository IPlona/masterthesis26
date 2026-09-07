using UnityEngine;
using UnityEngine.SceneManagement;

public class GameLoaderBeh : MonoBehaviour
{
   


    public void LoadSceneName(string name)
    {
        //Do fancy loading stuff TODO
        SceneManager.LoadScene(name, LoadSceneMode.Single);
    }

    public void EndGameRequested()
    {
        //Do fancy stuff
        Application.Quit();
    }
}
