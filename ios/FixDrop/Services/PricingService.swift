import Foundation
import Combine

// MARK: - Endpoint configuration
// Shared backend URL for pricing, auth, repairs, messages, and technician/admin actions.
enum APIConfig {
    static let upstreamBaseURL = "https://api.vishthetica.ca"
#if targetEnvironment(simulator)
    static let baseURL = "http://127.0.0.1:3100"
#else
    static let baseURL = upstreamBaseURL
#endif
    static let pricingEndpoint = "\(baseURL)/api/pricing"
    static let pingEndpoint = "\(baseURL)/api/ping"

    static func checkConnectivity() async -> Bool {
        guard let url = URL(string: pingEndpoint) else { return false }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return http.statusCode == 200
        } catch {
            return false
        }
    }

    static func userFacingServerError(statusCode: Int, data: Data?, fallback: String) -> String {
        if let data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["error", "detail", "message"] {
                if let value = json[key] as? String,
                   !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return value
                }
            }
        }

        if let data,
           let body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !body.isEmpty {
            if statusCode == 530 && body.contains("1033") {
                return "FixDrop backend is offline right now. Cloudflare tunnel error 1033 means the public hostname is not connected to the Windows backend."
            }
            return "\(fallback) (Server \(statusCode): \(body))"
        }

        return "\(fallback) (Server \(statusCode))"
    }
}

// MARK: - Pricing Service
final class PricingService: ObservableObject {
    @Published private(set) var config:    PricingConfig = .fallback
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var source:    PricingSource = .fallback

    enum PricingSource {
        case fallback
        case cache
        case live
    }

    private let cacheKey = "fixdrop.pricingConfig.v1"
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadFromCache()
        Task { await fetch() }
    }

    @MainActor
    func fetch() async {
        isLoading = true
        lastError = nil

        guard let url = URL(string: APIConfig.pricingEndpoint) else {
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(PricingConfig.self, from: data)
            config    = decoded
            source    = .live
            lastError = nil
            saveToCache(data: data)
        } catch {
            lastError = "Could not reach pricing server. Using \(source == .cache ? "cached" : "built-in") prices."
        }
        isLoading = false
    }

    @MainActor
    func save(_ updated: PricingConfig) async throws {
        guard let url = URL(string: APIConfig.pricingEndpoint) else { return }
        var request        = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = UserDefaults.standard.string(forKey: "fixdrop.tech.token") ?? ""
        if !token.isEmpty { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody   = try JSONEncoder().encode(updated)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        config = updated
        source = .live
        if let data = try? JSONEncoder().encode(updated) { saveToCache(data: data) }
    }

    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(PricingConfig.self, from: data) else {
            config = .fallback
            source = .fallback
            return
        }
        config = decoded
        source = .cache
    }

    private func saveToCache(data: Data) {
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
}
