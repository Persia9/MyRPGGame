public interface ILoginView : IMVPView
{
    void DisplayUserData(string data);
    void SetPresenter(ILoginPresenter presenter);
}