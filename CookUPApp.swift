//
//  CookUPApp.swift
//  CookUP
//
//  Created by Tekup-mac-7 on 29/10/2025.
//

import SwiftUI
import Firebase
import FirebaseCore

@main
struct CookUPApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
           RootView()
        }
    }
    
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            FirebaseApp.configure()
            return true
      }

    }


}
