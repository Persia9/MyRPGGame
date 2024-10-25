using UnityEngine;
using Zenject;

public class TestMainScene : MonoBehaviour
{
    private ILoginPresenter loginPresenter;

    [Inject]
    public void Construct(ILoginPresenter presenter)
    {
        loginPresenter = presenter;
    }

    private void Start()
    {
        loginPresenter.LoadUserData();
    }
}