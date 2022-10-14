//
//  UnityFramework
//
//  Created by 应彧刚 on 2022/10/3.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <UDPController.h>

/** 这个端口可以随便设置*/
#define TEST_IP_PROT 9091
/** 替换成你需要连接服务器绑定的IP地址，不能随便输*/
#define TEST_IP_ADDR "192.168.11.2"


@implementation UnityAppController(UDPController)

typedef void(*CallBack)(const char* p);
CallBack receiveMsgCallback;
id thisClass;
int remotePort;
const char *remoteAddress;
void initUDP(CallBack callBack, int port ,const char *address)
{
    receiveMsgCallback = callBack;
    remotePort = port;
    remoteAddress = address;
    [thisClass  createSocket];
}

void sendUDP(const char* msg)
{
    sendMsg(msg);
}

/*
 Called when the category is loaded.  This is where the methods are swizzled
 out.
 */
+ (void)load {
  Method original;
  Method swizzled;

  original = class_getInstanceMethod(
      self, @selector(application:didFinishLaunchingWithOptions:));
  swizzled = class_getInstanceMethod(
      self,
      @selector(UDPController:didFinishLaunchingWithOptions:));
  method_exchangeImplementations(original, swizzled);
}
- (BOOL)UDPController:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"当程序载入后执行1111");
    thisClass = self;
    return  [self UDPController:application
            didFinishLaunchingWithOptions:launchOptions];
}

CFSocketRef _socketRef;

- (void) createSocket{
    [NSThread detachNewThreadSelector:@selector(createSocket1) toTarget:self withObject:nil];
   // [self connectServer:self];
}

- (void) createSocket1 {
    
    CFSocketContext sockContext = {0,(__bridge void *)(self),NULL,NULL,NULL};
    _socketRef = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, kCFSocketReadCallBack,ServerConnectCallBack, &sockContext);
    if (_socketRef != NULL) {
        NSLog(@"socket 创建成功");
        [self connect];
    }else {
        NSLog(@"socket 创建失败");
    }
}

- (void)connect {
    struct sockaddr_in addr;
    //清空指向的内存中的存储内容，因为分配的内存是随机的
    memset(&addr, 0, sizeof(addr));
    //设置协议族
    addr.sin_family = AF_INET;
    //设置端口
    addr.sin_port = htons(remotePort);
    //设置IP地址
    addr.sin_addr.s_addr = inet_addr(remoteAddress);
    CFDataRef dataRef = CFDataCreate(kCFAllocatorDefault,(UInt8 *)&addr, sizeof(addr));
    
    CFSocketError sockError = CFSocketConnectToAddress(_socketRef,dataRef,20);
    
    if (sockError == kCFSocketSuccess) {
        NSLog(@"socket 连接成功");
    }else if(sockError == kCFSocketError) {
        NSLog(@"socket 连接失败");
    }else if(sockError == kCFSocketTimeout) {
        NSLog(@"socket 连接超时");
    }
    // 加入循环中
    // 获取当前线程的RunLoop
    CFRunLoopRef runLoopRef = CFRunLoopGetCurrent();
    // 把Socket包装成CFRunLoopSource，最后一个参数是指有多个runloopsource通过同一个runloop时候顺序，如果只有一个source通常为0
    CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socketRef, 0);
    
    // 加入运行循环,第三个参数表示
    CFRunLoopAddSource(runLoopRef, //运行循环管
                       sourceRef, // 增加的运行循环源, 它会被retain一次
                       kCFRunLoopCommonModes //用什么模式把source加入到run loop里面,使用kCFRunLoopCommonModes可以监视所有通常模式添加source
                       );
    CFRunLoopRun();
    CFRelease(sourceRef);
    //[self send];
}

void sendMsg (const char * data){
        ssize_t sendLen = send(CFSocketGetNative(_socketRef), data, strlen(data) + 1, 0);
        if (sendLen > 0) {
            NSLog(@"发送成功");
        }else{
            NSLog(@"发送失败");
        }
}

void ServerConnectCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void * data, void *info) {
    NSLog(@"ServerConnectCallBack");
    UnityAppController *vc = (__bridge UnityAppController *)(info);
    if (data != NULL) {
        CFRelease(socket);
    }else {
        [vc performSelectorInBackground:@selector(recvData) withObject:nil];
    }
}

- (void)recvData {
    char buffer[512];
    long readData = recv(CFSocketGetNative(_socketRef), buffer, sizeof(buffer), 0);
    //接收到的数据
    NSString *content = [[NSString alloc] initWithBytes:buffer length:readData encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *data = [NSString stringWithFormat:@"收到消息：%@",content];
        NSLog(data);
    });
}
@end
