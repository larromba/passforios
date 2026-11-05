//
//  AppDelegate.swift
//  pass
//
//  Created by Mingshen Sun on 18/1/2017.
//  Copyright © 2017 Bob Sun. All rights reserved.
//

import CoreData
import passKit
import SVProgressHUD
import SwiftyUserDefaults
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        SVProgressHUD.setMinimumSize(CGSize(width: 150, height: 100))

        UNUserNotificationCenter.current().delegate = NotificationCenterDispatcher.shared

        return true
    }

    // MARK: - Scene Configuration

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )

        configuration.delegateClass = SceneDelegate.self

        return configuration
    }

    // MARK: - Supported Orientations

    func application(
        _: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        if window?.rootViewController is PasscodeLockViewController {
            window?.frame = UIScreen.main.bounds
        }

        return .all
    }

    // MARK: - Termination

    func applicationWillTerminate(_: UIApplication) {
        PersistenceController.shared.save()
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    enum ViewTag: Int {
        case blur = 100, appicon
    }

    var window: UIWindow?

    private var didConnect = false

    lazy var passcodeLockPresenter = PasscodeLockPresenter(mainWindow: window)

    // MARK: - Scene Lifecycle

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)

        // Load the existing Main storyboard.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window.rootViewController = storyboard.instantiateInitialViewController()

        self.window = window
        window.makeKeyAndVisible()

        passcodeLockPresenter.present(
            windowLevel: window.windowLevel.rawValue
        )

        didConnect = true

        // Handle quick action on launch.
        if let shortcutItem = connectionOptions.shortcutItem,
           shortcutItem.type == Globals.bundleIdentifier + ".search" {
            perform(#selector(postSearchNotification), with: nil, afterDelay: 0.4)
        }
    }

    func sceneWillResignActive(_: UIScene) {
        guard let window else {
            return
        }

        // Display blur effect.
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)

        blurEffectView.frame = window.bounds
        blurEffectView.tag = ViewTag.blur.rawValue
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        window.addSubview(blurEffectView)

        // Display app icon.
        let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? NSDictionary
        let primaryIconsDictionary = iconsDictionary?["CFBundlePrimaryIcon"] as? NSDictionary
        let iconFiles = primaryIconsDictionary?["CFBundleIconFiles"] as? [String]

        if let iconName = iconFiles?.last,
           let appIcon = UIImage(named: iconName) {
            let appIconView = UIImageView(image: appIcon)

            appIconView.layer.cornerRadius = appIcon.size.height / 5
            appIconView.layer.masksToBounds = true
            appIconView.center = CGPoint(
                x: window.bounds.midX,
                y: window.bounds.midY
            )
            appIconView.tag = ViewTag.appicon.rawValue

            window.addSubview(appIconView)
        }

        PersistenceController.shared.save()
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Release resources or save application state if necessary.
    }

    func sceneWillEnterForeground(_: UIScene) {
        guard didConnect else {
            return
        }

        passcodeLockPresenter.present(
            windowLevel: window?.windowLevel.rawValue
        )
    }

    func sceneDidBecomeActive(_: UIScene) {
        window?.viewWithTag(ViewTag.appicon.rawValue)?.removeFromSuperview()
        window?.viewWithTag(ViewTag.blur.rawValue)?.removeFromSuperview()
    }

    func sceneDidDisconnect(_: UIScene) {
        PersistenceController.shared.save()
        window = nil
    }

    // MARK: - Quick Actions

    @objc
    func postSearchNotification() {
        NotificationCenter.default.post(
            name: .passwordSearch,
            object: nil
        )
    }

    func windowScene(
        _: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard shortcutItem.type == Globals.bundleIdentifier + ".search",
              let tabBarController = window?.rootViewController as? UITabBarController else {
            completionHandler(false)
            return
        }

        tabBarController.selectedIndex = 0

        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            navigationController.popToRootViewController(animated: false)
        }

        perform(#selector(postSearchNotification), with: nil, afterDelay: 0.4)

        completionHandler(true)
    }
}
