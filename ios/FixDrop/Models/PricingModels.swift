import Foundation

struct PricingConfig: Codable {
    var estimateRanges: [String: EstimateRange]
    var guardrails: QuoteGuardrails
    var travelFees: [TravelFeeTier]
    var priorityFees: PriorityFees
    var defaultLineItems: [String: [LineItemTemplate]]
    var lastUpdated: String

    func estimateString(for issue: String) -> String {
        guard let range = estimateRanges[issue] else { return "$50-$200" }
        return "$\(Int(range.low))-$\(Int(range.high))"
    }

    func travelFee(forKm km: Double) -> Double {
        travelFees
            .sorted { $0.maxKm < $1.maxKm }
            .first { km <= $0.maxKm }?
            .fee ?? travelFees.last?.fee ?? 20
    }

    func quoteLineItems(for issue: String) -> [QuoteLineItem] {
        (defaultLineItems[issue] ?? defaultLineItems["Other"] ?? [])
            .map { QuoteLineItem(label: $0.label, amount: $0.amount) }
    }
}

struct EstimateRange: Codable {
    var low: Double
    var high: Double
}

struct QuoteGuardrails: Codable {
    var belowThreshold: Double
    var aboveThreshold: Double
}

struct TravelFeeTier: Codable {
    var maxKm: Double
    var fee: Double
    var label: String
}

struct PriorityFees: Codable {
    var asapMin: Double
    var asapMax: Double
    var bypassMin: Double
    var bypassMax: Double
    var asapTimeoutMin: Int
}

struct LineItemTemplate: Codable {
    var label: String
    var amount: Double
}

extension PricingConfig {
    static var fallback: PricingConfig {
        PricingConfig(
            estimateRanges: [
                "Screen": EstimateRange(low: 120, high: 240),
                "Battery": EstimateRange(low: 70, high: 110),
                "Back Glass": EstimateRange(low: 80, high: 150),
                "Speaker / Mic": EstimateRange(low: 60, high: 100),
                "Crashing": EstimateRange(low: 50, high: 90),
                "Software Issue": EstimateRange(low: 40, high: 80),
                "Buttons": EstimateRange(low: 55, high: 95),
                "Other": EstimateRange(low: 50, high: 200),
            ],
            guardrails: QuoteGuardrails(belowThreshold: 20, aboveThreshold: 60),
            travelFees: [
                TravelFeeTier(maxKm: 10, fee: 15, label: "0-10 km"),
                TravelFeeTier(maxKm: 30, fee: 25, label: "10-30 km"),
                TravelFeeTier(maxKm: 150, fee: 40, label: "30+ km"),
            ],
            priorityFees: PriorityFees(
                asapMin: 30,
                asapMax: 60,
                bypassMin: 15,
                bypassMax: 25,
                asapTimeoutMin: 30
            ),
            defaultLineItems: [
                "Screen": [
                    LineItemTemplate(label: "Screen Replacement", amount: 189),
                    LineItemTemplate(label: "Labor", amount: 45),
                    LineItemTemplate(label: "Travel Fee", amount: 20),
                ],
                "Battery": [
                    LineItemTemplate(label: "Battery Replacement", amount: 79),
                    LineItemTemplate(label: "Labor", amount: 30),
                    LineItemTemplate(label: "Travel Fee", amount: 20),
                ],
                "Back Glass": [
                    LineItemTemplate(label: "Back Glass Repair", amount: 120),
                    LineItemTemplate(label: "Labor", amount: 40),
                    LineItemTemplate(label: "Travel Fee", amount: 20),
                ],
                "Speaker / Mic": [
                    LineItemTemplate(label: "Speaker / Mic Repair", amount: 75),
                    LineItemTemplate(label: "Labor", amount: 30),
                    LineItemTemplate(label: "Travel Fee", amount: 20),
                ],
                "Software Issue": [
                    LineItemTemplate(label: "Software Repair", amount: 60),
                    LineItemTemplate(label: "Labor", amount: 25),
                    LineItemTemplate(label: "Travel Fee", amount: 20),
                ],
                "Other": [
                    LineItemTemplate(label: "Diagnostic & Repair", amount: 80),
                    LineItemTemplate(label: "Labor", amount: 35),
                    LineItemTemplate(label: "Travel Fee", amount: 20),
                ],
            ],
            lastUpdated: "built-in fallback"
        )
    }
}

struct ModelPricing: Codable {
    var found: Bool
    var screen: [ScreenQualityQuote]
    var battery: RepairQuote
    var backglass: RepairQuote

    var lowestScreenQuote: Double? {
        screen.compactMap { $0.quote }.min()
    }

    var highestScreenQuote: Double? {
        screen.compactMap { $0.quote }.max()
    }

    var screenRangeString: String? {
        guard let low = lowestScreenQuote, let high = highestScreenQuote else { return nil }
        if low == high { return "$\(Int(low))" }
        return "$\(Int(low))-$\(Int(high))"
    }
}

struct ScreenQualityQuote: Codable, Identifiable {
    var id = UUID()
    var quality: String
    var quote: Double?
    enum CodingKeys: String, CodingKey { case quality, quote }
}

struct RepairQuote: Codable {
    var quote: Double?
    var formatted: String { quote.map { "$\(Int($0))" } ?? "Contact us" }
}

extension PricingService {
    @MainActor
    func fetchModelPricing(for model: String) async -> ModelPricing? {
        let encoded = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
        guard let url = URL(string: "\(APIConfig.baseURL)/api/pricing/model/\(encoded)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ModelPricing.self, from: data)
            return decoded.found ? decoded : nil
        } catch {
            return nil
        }
    }
}
