using Zenject;

public class LoginPresenter : ILoginPresenter
{
    private readonly ILoginModel model;
    private readonly ILoginView view;

    [Inject]
    public LoginPresenter(ILoginModel model, ILoginView view)
    {
        this.model = model;
        this.view = view;
        view.SetPresenter(this);
    }

    public void LoadUserData()
    {
        string data = model.GetUserData();
        view.DisplayUserData(data);
    }

    public void UpdateUI()
    {
        view.Render();
    }
}