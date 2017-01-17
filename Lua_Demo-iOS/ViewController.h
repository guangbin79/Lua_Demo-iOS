//
//  ViewController.h
//  Lua_Demo-iOS
//
//  Created by 柏光宾 on 2016/12/5.
//  Copyright © 2016年 柏光宾. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <lua51/lauxlib.h>
#import <lua51/lualib.h>
#import <lua51/lua.h>

@interface ViewController : UIViewController

-(void)accessNetwork;
-(void)testNetwork;
-(void)testWebServer;

@end

