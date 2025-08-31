import Foundation

final class AzureOpenAIAdapter: ProviderAdapter {
    // Azure OpenAI
    // Base example: https://<resource>.openai.azure.com
    // List deployments: GET /openai/deployments?api-version=<ver>
    // Auth: header "api-key: <key>"

    private let apiVersion = "2023-05-15"

    func testHealth(provider: Provider) async -> TestResult {
        guard let (url, headers) = buildURLAndHeaders(provider: provider) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let client = HTTPClient(timeout: 6)
        do {
            _ = try await client.get(url: url, headers: headers)
            return TestResult(status: .success, message: NSLocalizedString("OK", comment: "OK"))
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 { hint = NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed") }
                else if code == 404 { hint = NSLocalizedString("ERR_ROUTE_HINT_AZURE", comment: "Azure route hint") }
                else if code == 429 { hint = NSLocalizedString("ERR_RATE_LIMITED", comment: "Rate limited") }
                else { hint = String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code) }
                let bodyText = body ?? ""
                return TestResult(status: .failure, message: bodyText.isEmpty ? hint : "\(hint): \(bodyText)")
            default:
                return TestResult(status: .failure, message: http.localizedDescription)
            }
        } catch {
            return TestResult(status: .failure, message: error.localizedDescription)
        }
    }

    func listModels(provider: Provider) async -> ([String], String?) {
        guard let (url, headers) = buildURLAndHeaders(provider: provider) else {
            return ([], NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let client = HTTPClient(timeout: 6)
        do {
            let resp = try await client.get(url: url, headers: headers)
            struct ValueItem: Decodable { let id: String?; let name: String? }
            struct Deployments: Decodable { let value: [ValueItem]? }
            let decoded = try JSONDecoder().decode(Deployments.self, from: resp.data)
            let names = (decoded.value ?? []).compactMap { $0.name ?? $0.id }
            return names.isEmpty ? ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) : (names, nil)
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 { hint = NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed") }
                else if code == 404 { hint = NSLocalizedString("ERR_ROUTE_HINT_AZURE", comment: "Azure route hint") }
                else if code == 429 { hint = NSLocalizedString("ERR_RATE_LIMITED", comment: "Rate limited") }
                else { hint = String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code) }
                let bodyText = body ?? ""
                return ([], bodyText.isEmpty ? hint : "\(hint): \(bodyText)")
            default:
                return ([], http.localizedDescription)
            }
        } catch {
            return ([], error.localizedDescription)
        }
    }

    private func buildURLAndHeaders(provider: Provider) -> (URL, [String: String])? {
        guard let base = URL(string: provider.baseURL) else { return nil }
        let url = base.appendingPathComponent("openai/deployments")
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var items = comps?.queryItems ?? []
        items.append(URLQueryItem(name: "api-version", value: apiVersion))
        comps?.queryItems = items
        guard let finalURL = comps?.url else { return nil }

        guard case let .bearer(keyRef) = provider.auth else { return nil }
        do {
            guard let k = try KeychainService.shared.read(account: keyRef) else { return nil }
            var headers = provider.extraHeaders
            headers["api-key"] = k
            return (finalURL, headers)
        } catch { return nil }
    }
}
