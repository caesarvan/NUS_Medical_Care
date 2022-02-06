//
//  AppDelegate.swift
//  bletool
//
//  Created by 莫凡 on 2021/3/3.
//

import Cocoa
import Firebase



@main
class AppDelegate: NSObject, NSApplicationDelegate,NSWindowDelegate {
    
    override init() {
        super.init()
        FirebaseApp.configure()
        print("init")
    }
      
//    var mainWindow:NSWindow!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        mainWindow = NSApplication.shared.windows[0]
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
//    func windowShouldClose(_ sender: NSWindow) -> Bool {
//        NSApp.terminate(self)
//        return true
//    }
//    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
//        if !flag {
//            mainWindow.makeKeyAndOrderFront(nil)
//        }
//        return true
//    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        
        return true
    }
    
}

