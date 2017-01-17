//
//  ViewController.m
//  Lua_Demo-iOS
//
//  Created by 柏光宾 on 2016/12/5.
//  Copyright © 2016年 柏光宾. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>

#import <ifaddrs.h>
#import <arpa/inet.h>

#import "HTCopyableLabel.h"
#import <RealReachability/RealReachability.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
   
    
//    [self accessNetwork];
//    [self testNetwork];
    [self testWebServer];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)accessNetwork {
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *urlSessionDataTask = [urlSession dataTaskWithURL:url
                                                         completionHandler:^(NSData * _Nullable data,
                                                                             NSURLResponse * _Nullable response,
                                                                             NSError * _Nullable error) {
                                                             if (error == nil && data != nil) {
                                                                 NSLog(@"-- reponse success");
                                                             }
                                                         }];
    [urlSessionDataTask resume];
}

-(void)testNetwork {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
    
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    NSLog(@"Initial reachability status:%@",@(status));
    
    if (status == RealStatusNotReachable)
    {
        NSLog(@"Network unreachable!");
    }
    
    if (status == RealStatusViaWiFi)
    {
        NSLog(@"Network wifi! Free!");
    }
    
    if (status == RealStatusViaWWAN)
    {
        NSLog(@"Network WWAN! In charge!");
    }
}

-(void)networkChanged:(NSNotification *)notification {
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];
    ReachabilityStatus previousStatus = [reachability previousReachabilityStatus];
    NSLog(@"networkChanged, currentStatus:%@, previousStatus:%@", @(status), @(previousStatus));
    
    if (status == RealStatusNotReachable)
    {
        NSLog(@"Network unreachable!");
    }
    
    if (status == RealStatusViaWiFi)
    {
        NSLog(@"Network wifi! Free!");
    }
    
    if (status == RealStatusViaWWAN)
    {
        NSLog(@"Network WWAN! In charge!");
    }
    
    WWANAccessType accessType = [GLobalRealReachability currentWWANtype];
    
    if (status == RealStatusViaWWAN)
    {
        if (accessType == WWANType2G)
        {
            NSLog(@"RealReachabilityStatus2G");
        }
        else if (accessType == WWANType3G)
        {
            NSLog(@"RealReachabilityStatus3G");
        }
        else if (accessType == WWANType4G)
        {
            NSLog(@"RealReachabilityStatus4G");
        }
        else
        {
            NSLog(@"Unknown RealReachability WWAN Status, might be iOS6");
        }
    }
}

-(void)testWebServer {
    printf("*** wsapi-xavante\r\n");
    const char * ip = getIpAddresses();
    UILabel* label=[[HTCopyableLabel alloc]init];
    label.frame=CGRectMake(100, 50, 200, 200);
    label.textAlignment=NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth=YES;
    
    if (ip) {
        label.text=[NSString stringWithFormat:@"http://%s:8080/hello.html", ip];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            start_httpserver(NULL);
        });
    } else {
        label.text=@"Please connect to Wi-Fi for testing.";
    }
    
    [self.view addSubview:label];
}

static void initSystem(lua_State *L) {
    lua_pushstring(L, ([[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] UTF8String]));
    lua_setglobal(L, "CachesDirectory");
    
    lua_pushstring(L, ([[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] UTF8String]));
    lua_setglobal(L, "DocumentsDirectory");
    
    lua_pushstring(L, ([[[NSBundle mainBundle] resourcePath] UTF8String]));
    lua_setglobal(L, "ResourceDirectory");
    
    lua_pushstring(L, ([NSTemporaryDirectory() UTF8String]));
    lua_setglobal(L, "TemporaryDirectory");
    
    luaL_dofile(L, ([[NSString stringWithFormat:@"%@/lua-script.zip$system.lua", [[NSBundle mainBundle] resourcePath]] UTF8String]));
}

static void *start_httpserver(void *data) {
    lua_State * L = lua_open();
    luaL_openlibs(L);
    initSystem(L);
    luaL_dostring(L, "require 'test.wsapi-xavante.xavante-example'");
    lua_close(L);
    return NULL;
}

static const char * getIpAddresses() {
    NSString *address = NULL;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi or is bridge which is the hotsopt
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] ||
                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"bridge"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return [address UTF8String];
}

@end
