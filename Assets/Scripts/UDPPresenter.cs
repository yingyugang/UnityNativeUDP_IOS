
using System;
using System.Runtime.InteropServices;
using AOT;
using UnityEngine;
using UnityEngine.UI;

public class UDPPresenter : MonoBehaviour
{
    public Button btnConnect;
    public Button btnSend;
    public Text text;

    delegate void CallBack(IntPtr param);
    static Action<string> OnCallback;

    private void Awake()
    {
        btnConnect.onClick.AddListener(() => {
            initUDP(OnReceive,9091,"192.168.11.2");
        });
        btnSend.onClick.AddListener(()=> {
            sendUDP("xxxxxx");
        });
        OnCallback = (str) =>
        {
            text.text = str;
        };
    }

    [DllImport("__Internal")]
    private static extern void initUDP(CallBack callBack,int port ,string address);

    [DllImport("__Internal")]
    private static extern void sendUDP(string msg);

    [MonoPInvokeCallback(typeof(CallBack))]
    static void OnReceive(IntPtr param)
    {
        string data = Marshal.PtrToStringAuto(param);
        OnCallback?.Invoke(data);
    }
}