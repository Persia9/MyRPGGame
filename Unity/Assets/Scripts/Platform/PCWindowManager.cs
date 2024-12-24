using UnityEngine;
#if UNITY_STANDALONE_WIN && !UNITY_EDITOR
using System;
using System.IO;
using System.Collections;
// using System.Drawing;
using System.Runtime.InteropServices;
using AOT;
#endif

public class PCWindowManager : MonoBehaviour
{
#if UNITY_STANDALONE_WIN && !UNITY_EDITOR
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private struct NOTIFYICONDATA
    {
        public uint cbSize;
        public IntPtr hWnd;
        public uint uID;
        public uint uFlags;
        public uint uCallbackMessage;
        public IntPtr hIcon;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string szTip;
    }

    // [StructLayout(LayoutKind.Sequential)]
    // private struct POINT
    // {
    //     public int X;
    //     public int Y;
    // }

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy,
        uint uFlags);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    /// <summary>
    /// 提取与指定文件关联的图标
    /// </summary>
    /// <param name="hInst">应用程序实例的句柄</param>
    /// <param name="lpIconPath">文件路径，图标将从该文件中提取</param>
    /// <param name="lpiIcon">图标的索引（用于多图标文件）</param>
    /// <returns></returns>
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr ExtractAssociatedIcon(IntPtr hInst, string lpIconPath, ref ushort lpiIcon);

    /// <summary>
    /// 托盘区域增删图片
    /// </summary>
    /// <param name="dwMessage">指定要执行的操作</param>
    /// <param name="lpData">包含托盘图标的信息，例如图标、提示文本、回调消息等</param>
    /// <returns></returns>
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    private static extern bool Shell_NotifyIcon(uint dwMessage, ref NOTIFYICONDATA lpData);

    /// <summary>
    /// 设置窗口属性（如窗口过程 WndProc、窗口样式等）
    /// </summary>
    /// <param name="hWnd">窗口的句柄</param>
    /// <param name="nIndex">要设置的属性索引</param>
    /// <param name="dwNewLong">新的属性值</param>
    /// <returns></returns>
    [DllImport("user32.dll")]
    private static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    /// <summary>
    /// 将消息传递到指定的窗口过程（WndProc）
    /// </summary>
    /// <param name="lpPrevWndFunc">原始窗口过程的指针</param>
    /// <param name="hWnd">窗口的句柄</param>
    /// <param name="msg">消息的编号</param>
    /// <param name="wParam">消息的附加参数 通常用于传递一个简单的、较小的数据值（例如 状态标志、按钮ID 或者 键盘扫描码）</param>
    /// <param name="lParam">消息的附加参数 通常用于传递更复杂的数据，比如结构体的指针、坐标信息，或者多个数据合并成的一个值</param>
    /// <returns></returns>
    [DllImport("user32.dll")]
    private static extern IntPtr CallWindowProc(IntPtr lpPrevWndFunc, IntPtr hWnd, uint msg, IntPtr wParam,
        IntPtr lParam);

    // [DllImport("user32.dll")]
    // private static extern IntPtr CreatePopupMenu();
    //
    // [DllImport("user32.dll")]
    // private static extern bool AppendMenu(IntPtr hMenu, uint uFlags, uint uIDNewItem, string lpNewItem);
    //
    // [DllImport("user32.dll")]
    // private static extern int TrackPopupMenu(IntPtr hMenu, uint uFlags, int x, int y, int nReserved, IntPtr hWnd,
    //     IntPtr prcRect);
    //
    // [DllImport("user32.dll")]
    // private static extern bool DestroyMenu(IntPtr hMenu);
    //
    // [DllImport("user32.dll")]
    // private static extern bool GetCursorPos(out POINT lpPoint);

    private const int NIM_ADD = 0x00000000;
    private const int NIM_DELETE = 0x00000002;
    private const int NIF_MESSAGE = 0x00000001;
    private const int NIF_ICON = 0x00000002;
    private const int GWL_WNDPROC = -4;

    private const int WM_USER = 0x0400;

    // private const int WM_COMMAND = 0x0111;
    private const int WM_LBUTTONUP = 0x0202;
    // private const int WM_RBUTTONUP = 0x0205;

    private const uint SWP_NOSIZE = 0x0001;
    private const uint SWP_NOMOVE = 0x0002;

    // 隐藏窗口，窗口不会显示在任务栏中
    private const int SW_HIDE = 0;

    // 显示窗口，如果窗口最小化或最大化，会还原到之前的状态（不激活）
    // private const int SW_SHOW = 5;
    // 最小化窗口并激活Z顺序中的下一个顶级窗口
    // private const int SW_MINIMIZE = 6;
    // 激活窗口并将窗口还原到原始大小和位置
    private const int SW_RESTORE = 9;

    // private const int ID_OPEN_APP = 1;
    // private const int ID_EXIT_APP = 2;

    private static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    private static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

    private static IntPtr hWnd = IntPtr.Zero;
    private NOTIFYICONDATA notifyIconData;
    private static IntPtr oldWndProc;
    private static WndProcDelegate newWndProc;

    private delegate IntPtr WndProcDelegate(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    void Start()
    {
        DontDestroyOnLoad(gameObject);
        StartCoroutine(GetUnityWindowHandleAfterDelay());
    }

    IEnumerator GetUnityWindowHandleAfterDelay()
    {
        // 等待窗口初始化
        yield return new WaitForSeconds(1f);
        hWnd = GetUnityWindowHandle();
        if (hWnd == IntPtr.Zero)
        {
            Debug.LogError("无法找到 Unity 窗口句柄。");
        }

        string exeDirectory = Path.GetFullPath(Path.Combine(Application.dataPath, "../"));
        // EXE 文件名通常与项目名称一致
        string exeName = Path.GetFileNameWithoutExtension(Application.productName) + ".exe";
        string exePath = Path.Combine(exeDirectory, exeName);

        // 提取当前 EXE 文件的图标
        ushort iconIndex = 0;
        IntPtr hIcon = ExtractAssociatedIcon(IntPtr.Zero, exePath, ref iconIndex);

        notifyIconData = new NOTIFYICONDATA
        {
            cbSize = (uint)Marshal.SizeOf(typeof(NOTIFYICONDATA)),
            hWnd = hWnd,
            uID = 100,
            uFlags = NIF_MESSAGE | NIF_ICON,
            uCallbackMessage = WM_USER + 1,
            hIcon = hIcon,
            szTip = "",
        };

        Shell_NotifyIcon(NIM_ADD, ref notifyIconData);

        newWndProc = CustomWndProc;
        oldWndProc = SetWindowLongPtr(hWnd, GWL_WNDPROC, Marshal.GetFunctionPointerForDelegate(newWndProc));
    }

    [MonoPInvokeCallback(typeof(Action))]
    private static IntPtr CustomWndProc(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam)
    {
        if (msg == WM_USER + 1)
        {
            switch (lParam.ToInt32())
            {
                case WM_LBUTTONUP:
                {
                    if (hWnd != IntPtr.Zero)
                    {
                        ShowWindow(hWnd, SW_RESTORE);
                    }

                    break;
                }
                // case WM_RBUTTONUP:
                //     ShowContextMenu();
                //     break;
            }
        }
        // else if (msg == WM_COMMAND)
        // {
        //     switch (wParam.ToInt32())
        //     {
        //         case ID_OPEN_APP:
        //         {
        //             if (hWnd != IntPtr.Zero)
        //             {
        //                 ShowWindow(hWnd, SW_RESTORE);
        //             }
        //
        //             break;
        //         }
        //         case ID_EXIT_APP:
        //             Application.Quit();
        //             break;
        //     }
        // }

        return CallWindowProc(oldWndProc, hWnd, msg, wParam, lParam);
    }

    // /// <summary>
    // /// 右键菜单
    // /// </summary>
    // private static void ShowContextMenu()
    // {
    //     IntPtr hMenu = CreatePopupMenu();
    //     AppendMenu(hMenu, 0, 1, "Open");
    //     AppendMenu(hMenu, 0, 2, "Close");
    //
    //     GetCursorPos(out var point);
    //     TrackPopupMenu(hMenu, 0x0002 | 0x0100, point.X, point.Y, 0, hWnd, IntPtr.Zero);
    //     DestroyMenu(hMenu);
    // }

    /// <summary>
    /// 获取窗口句柄
    /// </summary>
    /// <returns></returns>
    private IntPtr GetUnityWindowHandle()
    {
        string title = Application.productName;
        IntPtr hWnd = FindWindow(null, title);
        return hWnd;
    }

    /// <summary>
    /// 开启置顶
    /// </summary>
    /// <param name="hWnd"></param>
    private void SetWindowAlwaysOnTop(IntPtr hWnd)
    {
        SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
    }

    /// <summary>
    /// 取消置顶
    /// </summary>
    /// <param name="hWnd"></param>
    private void CancelWindowAlwaysOnTop(IntPtr hWnd)
    {
        SetWindowPos(hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
    }

    private void OnApplicationQuit()
    {
        Shell_NotifyIcon(NIM_DELETE, ref notifyIconData);
    }

    /// <summary>
    /// 切换窗口置顶
    /// </summary>
    /// <param name="isTopMost"></param>
    public void ToggleWindowTopMost(bool isTopMost)
    {
        if (hWnd != IntPtr.Zero)
        {
            if (isTopMost)
            {
                SetWindowAlwaysOnTop(hWnd);
            }
            else
            {
                CancelWindowAlwaysOnTop(hWnd);
            }
        }
    }

    /// <summary>
    /// 最小化窗口到托盘区且隐藏任务栏
    /// </summary>
    public void MinimizeWindow()
    {
        if (hWnd != IntPtr.Zero)
        {
            ShowWindow(hWnd, SW_HIDE);
        }
    }
#endif
}