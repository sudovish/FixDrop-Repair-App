import SwiftUI
import UIKit
import EventKit
import UserNotifications

extension Notification.Name {
    static let fixDropDeviceTokenDidUpdate = Notification.Name("FixDropDeviceTokenDidUpdate")
}

final class FixDropAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var store: RepairStore?

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
        let tokenPreview = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("FixDrop APNs registration succeeded: \(tokenPreview)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("FixDrop remote notification registration failed: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let store else {
            completionHandler(.noData)
            return
        }

        Task {
            await store.refreshDataForCurrentRoleAsync()
            completionHandler(.newData)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .badge, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        print("FixDrop notification response received: \(response.notification.request.content.userInfo)")
        await MainActor.run {
            store?.startAutoRefresh()
        }
    }
}

enum FixDropNotifications {
    static let deviceTokenKey = "fixdrop.apns.token"

    static var apnsEnvironment: String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
    }

    static func requestAuthorization() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
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
        NotificationCenter.default.post(name: .fixDropDeviceTokenDidUpdate, object: token)
    }

    static var storedDeviceToken: String? {
        let token = UserDefaults.standard.string(forKey: deviceTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return token.isEmpty ? nil : token
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

enum FixDropCalendarSync {
    private static let syncedAppointmentKey = "fixdrop.calendar.syncedAppointments"

    static func syncAppointmentIfNeeded(_ appointment: Appointment, repair: RepairRequest) {
        Task {
            do {
                let signature = syncSignature(for: appointment, repair: repair)
                let synced = Set(UserDefaults.standard.stringArray(forKey: syncedAppointmentKey) ?? [])
                guard !synced.contains(signature) else { return }

                let store = EKEventStore()
                let granted = try await requestCalendarAccess(store: store)
                guard granted, let calendar = store.defaultCalendarForNewEvents else { return }

                let event = EKEvent(eventStore: store)
                event.calendar = calendar
                event.title = "FixDrop Repair - \(repair.displayDeviceName)"
                event.startDate = appointment.scheduledAt
                event.endDate = appointment.scheduledAt.addingTimeInterval(60 * 60)
                event.location = appointment.displayLocation.isEmpty ? repair.location : appointment.displayLocation
                event.notes = eventNotes(for: appointment, repair: repair)
                event.alarms = defaultAlarms(for: appointment.scheduledAt)

                try store.save(event, span: .thisEvent, commit: true)

                var updated = synced
                updated.insert(signature)
                UserDefaults.standard.set(Array(updated), forKey: syncedAppointmentKey)
            } catch {
                print("FixDrop calendar sync failed: \(error.localizedDescription)")
            }
        }
    }

    private static func requestCalendarAccess(store: EKEventStore) async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToEvents()
        }

        return try await withCheckedThrowingContinuation { continuation in
            store.requestAccess(to: .event) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private static func syncSignature(for appointment: Appointment, repair: RepairRequest) -> String {
        let timestamp = Int(appointment.scheduledAt.timeIntervalSince1970)
        return "\(appointment.id.uuidString.lowercased())|\(timestamp)|\(repair.id.uuidString.lowercased())"
    }

    private static func eventNotes(for appointment: Appointment, repair: RepairRequest) -> String {
        var lines: [String] = []
        lines.append("Issue: \(repair.issue)")
        lines.append("Mode: \(appointment.mode.rawValue)")

        if !repair.assignedTechnicianDisplayName.isEmpty {
            lines.append("Technician: \(repair.assignedTechnicianDisplayName)")
        }

        if !appointment.displayNote.isEmpty {
            lines.append("Notes: \(appointment.displayNote)")
        }

        return lines.joined(separator: "\n")
    }

    private static func defaultAlarms(for date: Date) -> [EKAlarm] {
        var alarms: [EKAlarm] = []
        let secondsUntil = date.timeIntervalSinceNow

        if secondsUntil > 2 * 60 * 60 {
            alarms.append(EKAlarm(relativeOffset: -(2 * 60 * 60)))
        }
        if secondsUntil > 24 * 60 * 60 {
            alarms.append(EKAlarm(relativeOffset: -(24 * 60 * 60)))
        }
        if alarms.isEmpty, secondsUntil > 15 * 60 {
            alarms.append(EKAlarm(relativeOffset: -(15 * 60)))
        }

        return alarms
    }
}

@main
struct FixDropApp: App {
    @UIApplicationDelegateAdaptor(FixDropAppDelegate.self) private var appDelegate
    @StateObject private var store   = RepairStore()
    @StateObject private var pricing = PricingService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(pricing)
                .onAppear {
                    appDelegate.store = store
                    store.pricingService = pricing
                    FixDropNotifications.requestAuthorization()
                }
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .active:
                        store.startAutoRefresh()
                    case .background:
                        store.stopAutoRefresh()
                    default:
                        break
                    }
                }
        }
    }
}
