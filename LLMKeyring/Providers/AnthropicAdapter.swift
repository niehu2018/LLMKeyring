import Foundation

final class AnthropicAdapter: ProviderAdapter {
    // Anthropic API
    // Base: https://api.anthropic.com
    // Models: GET /v1/models with headers:
    //   x-api-key: <key>
    //   anthropic-version: 2023-06-01

    private let apiVersion = "2023-06-01"

    func testHealth(provider: Provider) async -> TestResult {
        guard let base = URL(string: provider.baseURL) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let url = normalize(base: base)
        var headers = provider.extraHeaders
        headers["anthropic-version"] = apiVersion
        guard case let .bearer(keyRef) = provider.auth else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed hint"))
        }
        do {
            guard let k = try KeychainService.shared.read(account: keyRef) else {
                return TestResult(status: .failure, message: NSLocalizedString("ERR_KEYCHAIN_MISSING", comment: "Keychain credential missing"))
            }
            headers["x-api-key"] = k
        } catch {
            return TestResult(status: .failure, message: error.localizedDescription)
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
        guard let base = URL(string: provider.baseURL) else {
            return ([], NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let url = normalize(base: base)
        var headers = provider.extraHeaders
        headers["anthropic-version"] = apiVersion
        guard case let .bearer(keyRef) = provider.auth else {
            return ([], NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed"))
        }
        do {
            guard let k = try KeychainService.shared.read(account: keyRef) else {
                return ([], NSLocalizedString("ERR_KEYCHAIN_MISSING", comment: "Keychain credential missing"))
            }
            headers["x-api-key"] = k
        } catch {
            return ([], error.localizedDescription)
        }
        let client = HTTPClient(timeout: 6)
        do {
            let resp = try await client.get(url: url, headers: headers)
            struct ModelsResp: Decodable { struct Item: Decodable { let id: String }
                let data: [Item] }
            let decoded = try JSONDecoder().decode(ModelsResp.self, from: resp.data)
            let ids = decoded.data.map { $0.id }
            return ids.isEmpty ? ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) : (ids, nil)
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 { hint = NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed") }
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

    private func normalize(base: URL) -> URL {
        let trimmed = base.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.hasSuffix("v1") {
            return base.appendingPathComponent("models")
        } else {
            return base.appendingPathComponent("v1/models")
        }
    }
}

