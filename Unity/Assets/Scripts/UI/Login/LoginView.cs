using System;
using UnityEngine;

public class LoginView : ILoginView
{
    private ILoginPresenter presenter;

    public void DisplayUserData(string data)
    {
        Console.WriteLine($"User Data: {data}");
    }

    public void SetPresenter(ILoginPresenter presenter)
    {
        this.presenter = presenter;
    }

    public void Render()
    {
        Console.WriteLine("Rendering Login View...");
    }
}