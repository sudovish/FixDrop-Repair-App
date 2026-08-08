import SwiftUI
import UIKit
import UserNotifications

final class FixDropAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        FixDropNotifications.storeDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("FixDrop remote notification registration failed: \(error.localizedDescription)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .badge, .sound]
    }
}

enum FixDropNotifications {
    static let deviceTokenKey = "fixdrop.apns.token"

    static func requestAuthorization() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .timeSensitive])
                guard granted else { return }
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } catch {
                print("FixDrop notification permission request failed: \(error.localizedDescription)")
            }
        }
    }

    static func storeDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: deviceTokenKey)
    }

    static func scheduleTimeSensitive(title: String, body: String, threadIdentifier: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.threadIdentifier = threadIdentifier
            content.interruptionLevel = .timeSensitive

            let request = UNNotificationRequest(
                identifier: "\(threadIdentifier).\(UUID().uuidString)",
                content: content,
                trigger: nil
            )

            do {
                try await center.add(request)
            } catch {
                print("FixDrop local notification scheduling failed: \(error.localizedDescription)")
            }
        }
    }
}

@main
struct FixDropApp: App {
    @UIApplicationDelegateAdaptor(FixDropAppDelegate.self) private var appDelegate
    @StateObject private var store   = RepairStore()
    @StateObject private var pricing = PricingService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(pricing)
                .onAppear {
                    store.pricingService = pricing
                    FixDropNotifications.requestAuthorization()
                }
        }
    }
}
