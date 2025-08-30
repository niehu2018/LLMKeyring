import Foundation

final class OpenAICompatibleAdapter: ProviderAdapter {
    func testHealth(provider: Provider) async -> TestResult {
        guard let base = URL(string: provider.baseURL) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        // Normalize: if base already ends with /v1, append models; otherwise append v1/models
        let path = base.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endsWithV1 = path.hasSuffix("v1")
        let url = endsWithV1 ? base.appendingPathComponent("models") : base.appendingPathComponent("v1/models")
        var headers = provider.extraHeaders
        if case let .bearer(keyRef) = provider.auth {
            do {
                if let key = try KeychainService.shared.read(account: keyRef) {
                    headers["Authorization"] = "Bearer \(key)"
                } else {
                    return TestResult(status: .failure, message: NSLocalizedString("ERR_KEYCHAIN_MISSING", comment: "Keychain credential missing"))
                }
            } catch {
                return TestResult(status: .failure, message: error.localizedDescription)
            }
        }
        let client = HTTPClient(timeout: 5)
        do {
            _ = try await client.get(url: url, headers: headers)
            return TestResult(status: .success, message: NSLocalizedString("OK", comment: "OK"))
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 {
                    hint = NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed hint")
                } else if code == 404 {
                    hint = NSLocalizedString("ERR_ROUTE_HINT_ALIYUN", comment: "Route error hint")
                } else if code == 429 {
                    hint = NSLocalizedString("ERR_RATE_LIMITED", comment: "Rate limited")
                } else {
                    hint = String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code)
                }
                let bodyText = body ?? ""
                let combined = bodyText.isEmpty ? hint : "\(hint): \(bodyText)"
                return TestResult(status: .failure, message: combined)
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
        let path = base.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endsWithV1 = path.hasSuffix("v1")
        let url = endsWithV1 ? base.appendingPathComponent("models") : base.appendingPathComponent("v1/models")
        var headers = provider.extraHeaders
        if case let .bearer(keyRef) = provider.auth {
            do {
                guard let k = try KeychainService.shared.read(account: keyRef) else {
                    return ([], NSLocalizedString("ERR_KEYCHAIN_MISSING", comment: "Keychain credential missing"))
                }
                headers["Authorization"] = "Bearer \(k)"
            } catch {
                return ([], error.localizedDescription)
            }
        }
        let client = HTTPClient(timeout: 5)
        do {
            let resp = try await client.get(url: url, headers: headers)
            struct ModelsResp: Decodable { struct Item: Decodable { let id: String }
                let data: [Item] }
            let decoded = try JSONDecoder().decode(ModelsResp.self, from: resp.data)
            let ids = decoded.data.map { $0.id }
            if ids.isEmpty { return ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) }
            return (ids, nil)
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 { hint = NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed") }
                else if code == 404 { hint = NSLocalizedString("ERR_ROUTE_HINT_ALIYUN", comment: "Route hint") }
                else if code == 429 { hint = NSLocalizedString("ERR_RATE_LIMITED", comment: "Rate limited") }
                else { hint = String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code) }
                let bodyText = body ?? ""
                let combined = bodyText.isEmpty ? hint : "\(hint): \(bodyText)"
                return ([], combined)
            default:
                return ([], http.localizedDescription)
            }
        } catch {
            return ([], error.localizedDescription)
        }
    }
}
