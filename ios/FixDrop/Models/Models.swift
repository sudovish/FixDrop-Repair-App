import Foundation
import UIKit

func fixDropNormalizedPhone(_ value: String) -> String {
    let digits = value.filter(\.isNumber)
    if digits.isEmpty { return "" }
    if digits.count == 10 { return "+1\(digits)" }
    if digits.count == 11 && digits.first == "1" { return "+\(digits)" }
    return "+\(digits)"
}

func fixDropDisplayPhone(_ value: String) -> String {
    let digits = value.filter(\.isNumber)
    let localDigits: String
    if digits.count == 11 && digits.first == "1" {
        localDigits = String(digits.dropFirst())
    } else if digits.count == 10 {
        localDigits = digits
    } else {
        return value
    }

    let area = localDigits.prefix(3)
    let mid = localDigits.dropFirst(3).prefix(3)
    let last = localDigits.suffix(4)
    return "(\(area)) \(mid)-\(last)"
}

enum RequestStatus: String, CaseIterable {
    case submitted = "Submitted"
    case dispatching = "Dispatching"
    case accepted = "Accepted"
    case inProgress = "In Progress"
    case quoted = "Quoted"
    case scheduled = "Scheduled"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .submitted: return "tray.and.arrow.up"
        case .dispatching: return "location.circle"
        case .accepted: return "person.fill.checkmark"
        case .inProgress: return "wrench.and.screwdriver"
        case .quoted: return "doc.text"
        case .scheduled: return "calendar"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

struct RepairRequest: Identifiable {
    var id = UUID()
    var brand = ""
    var model = ""
    var issue = ""
    var symptoms: [String] = []
    var additionalDescription = ""
    var photos: [UIImage] = []
    var phoneNumber = ""
    var location = ""
    var preferredDays: [String] = []
    var preferredDates: [Date] = []
    var preferredTime = ""
    var additionalNote = ""
    var isUrgent = false
    var isTradeIn = false
    var status: RequestStatus = .submitted
    var submittedAt: Date = Date()
    var assignedTechnicianId: UUID?
    var assignedTechnicianName: String?
    var quotes: [Quote] = []
    var messages: [ChatMessage] = []
    var appointment: Appointment?
    var distance: Double = Double.random(in: 1.5...8.5)

    var issueNames: [String] {
        issue
            .split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var primaryIssue: String {
        issueNames.first ?? issue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayPhoneNumber: String {
        fixDropDisplayPhone(phoneNumber)
    }

    func estimatedRange(pricing: PricingConfig = .fallback) -> String {
        pricing.estimateString(for: primaryIssue)
    }

    var activeQuote: Quote? {
        quotes.last(where: { $0.status == .approved || $0.status == .pending })
    }
}

enum TechnicianRole: String { case technician, admin }

struct Technician: Identifiable {
    var id = UUID()
    var name: String
    var phone: String
    var email: String
    var password: String = "fix123"
    var role: TechnicianRole = .technician
    var isOnDuty = false
    var radiusKm: Double = 25
    var specialties: [String] = ["Screen", "Battery", "Back Glass", "Software Issue"]
    var region = "Surrey, BC"
    var responseTime = "~4 min avg"
    var rating: Double = 4.8
    var jobsCompleted = 0
    var isApproved = true
    var latitude: Double = 49.1913
    var longitude: Double = -122.8490
    var authToken: String? = nil
}

struct Quote: Identifiable {
    var id = UUID()
    var requestId: UUID
    var technicianId: UUID
    var technicianName: String
    var lineItems: [QuoteLineItem]
    var sentAt: Date = Date()
    var status: QuoteStatus = .pending
    var adminNote = ""
    var requiresApproval = false
    var revisionNote = ""

    var total: Double { lineItems.reduce(0) { $0 + $1.amount } }
    var formattedTotal: String { String(format: "$%.0f", total) }
}

enum QuoteStatus: String { case pending, approved, rejected, adminReview }

struct QuoteLineItem: Identifiable {
    var id = UUID()
    var label: String
    var amount: Double
    var formattedAmount: String { String(format: "$%.0f", amount) }
}

struct ChatMessage: Identifiable {
    var id = UUID()
    var requestId: UUID
    var senderId: UUID
    var senderName: String
    var body: String
    var sentAt: Date = Date()
    var isSystem = false
    var isFromCustomer: Bool
}

struct Appointment: Identifiable {
    var id = UUID()
    var requestId: UUID
    var scheduledAt: Date
    var mode: RepairMode = .onsite
    var note = ""
    var confirmed = false
}

enum RepairMode: String, CaseIterable {
    case onsite = "Onsite Repair"
    case offsite = "Pickup & Return"
    case dropoff = "Customer Drop-Off"

    var icon: String {
        switch self {
        case .onsite: return "house.and.flag"
        case .offsite: return "arrow.triangle.2.circlepath"
        case .dropoff: return "building.2"
        }
    }

    var feeNote: String {
        switch self {
        case .onsite: return "Base + travel fee"
        case .offsite: return "Base + pickup + return fee"
        case .dropoff: return "Base price only - most affordable"
        }
    }
}

struct PhoneBrand: Identifiable {
    let id = UUID()
    let name: String
    let sfIcon: String
}

let phoneBrands: [PhoneBrand] = [
    PhoneBrand(name: "Apple / iPhone", sfIcon: "applelogo"),
    PhoneBrand(name: "Samsung", sfIcon: "s.circle.fill"),
    PhoneBrand(name: "Google Pixel", sfIcon: "g.circle.fill"),
    PhoneBrand(name: "Motorola", sfIcon: "m.circle.fill"),
    PhoneBrand(name: "Other", sfIcon: "questionmark.circle.fill"),
]

let appleModels: [String] = [
    "iPhone 16 Pro Max", "iPhone 16 Pro", "iPhone 16 Plus", "iPhone 16", "iPhone 16e",
    "iPhone 15 Pro Max", "iPhone 15 Pro", "iPhone 15 Plus", "iPhone 15",
    "iPhone 14 Pro Max", "iPhone 14 Pro", "iPhone 14 Plus", "iPhone 14",
    "iPhone 13 Pro Max", "iPhone 13 Pro", "iPhone 13 mini", "iPhone 13",
    "iPhone 12 Pro Max", "iPhone 12 Pro", "iPhone 12 mini", "iPhone 12",
    "iPhone 11 Pro Max", "iPhone 11 Pro", "iPhone 11",
    "iPhone XS Max", "iPhone XS", "iPhone XR", "iPhone X",
    "iPhone 8 Plus", "iPhone 8", "iPhone 7 Plus", "iPhone 7",
    "iPhone SE (3rd Gen)", "iPhone SE (2nd Gen)", "iPhone SE (1st Gen)"
]

let samsungModels = ["Galaxy S24 Ultra", "Galaxy S24+", "Galaxy S24", "Galaxy S23 Ultra", "Galaxy S23+", "Galaxy S23", "Galaxy Z Fold 5", "Galaxy Z Flip 5", "Galaxy A55", "Galaxy A35"]
let googlePixelModels = ["Pixel 9 Pro XL", "Pixel 9 Pro Fold", "Pixel 9 Pro", "Pixel 9", "Pixel 8 Pro", "Pixel 8", "Pixel 8a", "Pixel 7 Pro", "Pixel 7", "Pixel 7a"]
let motorolaModels = ["Edge 50 Ultra", "Edge 50 Pro", "Edge 50 Fusion", "Moto G84", "Moto G54", "Moto G34", "Razr 50 Ultra", "Razr 50"]

func modelsFor(brand: String) -> [String] {
    switch brand {
    case "Apple / iPhone": return appleModels
    case "Samsung": return samsungModels
    case "Google Pixel": return googlePixelModels
    case "Motorola": return motorolaModels
    default: return []
    }
}

struct IssueType: Identifiable {
    var id = UUID()
    let icon: String
    let name: String
}

let issueTypes: [IssueType] = [
    IssueType(icon: "display", name: "Screen"),
    IssueType(icon: "battery.25", name: "Battery"),
    IssueType(icon: "square.3.layers.3d", name: "Back Glass"),
    IssueType(icon: "speaker.wave.2", name: "Speaker / Mic"),
    IssueType(icon: "cpu", name: "Crashing"),
    IssueType(icon: "gearshape", name: "Software Issue"),
    IssueType(icon: "switch.2", name: "Buttons"),
    IssueType(icon: "questionmark.circle", name: "Other")
]

let symptomsMap: [String: [String]] = [
    "Screen": ["Cracked screen", "Black screen", "Touch not responding", "Screen flickering", "Lines on screen"],
    "Battery": ["Battery drains fast", "Won't charge", "Phone shuts off randomly", "Swollen battery", "Charging slowly"],
    "Back Glass": ["Cracked back glass", "Shattered back", "Back glass popping off"],
    "Speaker / Mic": ["No sound", "Muffled audio", "Mic not working", "Speaker crackle", "Earpiece not working"],
    "Crashing": ["App keeps crashing", "Phone restarts randomly", "Stuck on boot screen", "Freezes frequently", "Something else"],
    "Software Issue": ["iOS / Android not updating", "Apps won't open", "Data loss", "Settings issues", "Restore needed"],
    "Buttons": ["Home button broken", "Volume buttons broken", "Power button broken", "Face ID / Fingerprint not working"],
    "Other": ["Water damage", "Camera issue", "Charging port broken", "Something else"]
]

let preferredDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
let preferredTimes = ["Morning (8am-12pm)", "Afternoon (12pm-5pm)", "Evening (5pm-9pm)", "Anytime"]
let homeIssueCards = [("display", "Screen"), ("battery.25", "Battery"), ("square.3.layers.3d", "Back Glass"), ("gearshape", "Software")]
let whyFixDrop = [
    ("clock", "Fast turnaround, same-day when possible"),
    ("shield", "Genuine & quality aftermarket parts"),
    ("star", "Transparent pricing, no hidden fees"),
    ("location.circle", "On-demand, at your location")
]
