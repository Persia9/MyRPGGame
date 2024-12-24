using Zenject;

public class MVPInstaller : MonoInstaller
{
    public override void InstallBindings()
    {
        // 绑定接口到具体实现
        Container.Bind<ILoginModel>().To<LoginModel>().AsTransient();
        Container.Bind<ILoginView>().To<LoginView>().AsTransient();
        Container.Bind<ILoginPresenter>().To<LoginPresenter>().AsTransient();
    }
}