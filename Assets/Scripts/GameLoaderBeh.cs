using UnityEngine;
using UnityEngine.SceneManagement;

public class GameLoaderBeh : MonoBehaviour
{
    [SerializeField] string currentScene;

    public void Start()
    {
        currentScene = SceneManager.GetActiveScene().name;


        switch (currentScene)
        {
            case "mainMenu":
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
                break;
            case "gameWorld":
                Cursor.lockState = CursorLockMode.Locked;
                Cursor.visible = false;
                break;
        }
        if (currentScene == "mainMenu")
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }
        
    }

    public void Update()
    {
        if (Input.GetKeyDown("p"))
        {
            switch (currentScene)
            {
                case "mainMenu":
                    //We quit
                    EndGameRequested();
                    break;
                case "gameWorld":
                    //We go to mainmenu
                    LoadSceneName("mainMenu");
                    break;
            }
        }
    }

    public void LoadSceneName(string name)
    {
        //Do fancy loading stuff TODO
        SceneManager.LoadScene(name, LoadSceneMode.Single);
    }

    public void EndGameRequested()
    {
        //Do fancy stuff
        Debug.Log("Quitting the game");
        Application.Quit();
    }
}
