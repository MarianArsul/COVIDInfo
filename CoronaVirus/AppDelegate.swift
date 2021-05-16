//
//  AppDelegate.swift
//  CoronaVirus
//
//  Created by Milovan on 03.03.2021.
//

import UIKit
import PDFNet

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        articlePresentedScrape()
        //newsExtendedOne(url: "https://stirioficiale.ro/informatii/actualizare-zilnica-02-05-evidenta-persoanelor-vaccinate-impotriva-covid-19")
        newsExtendedTwo(url: "https://stirioficiale.ro/informatii/buletin-de-presa-4-mai-2021-ora-13-00")
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            PTPDFNet.initialize("Insert Commercial License Key Here After Purchase")
            return true
        }


}

