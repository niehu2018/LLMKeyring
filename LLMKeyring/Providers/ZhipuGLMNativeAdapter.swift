import Foundation

final class ZhipuGLMNativeAdapter: ProviderAdapter {
    // Zhipu GLM Native
    // Base examples:
    //  - https://open.bigmodel.cn
    //  - https://open.bigmodel.cn/api/paas
    // Health/List models: GET .../api/paas/v4/models (Authorization: Bearer <key>)

    func testHealth(provider: Provider) async -> TestResult {
        guard let (url, headers) = buildModelsURLAndHeaders(provider: provider) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let client = HTTPClient(timeout: 8)
        do {
            _ = try await client.get(url: url, headers: headers)
            return TestResult(status: .success, message: NSLocalizedString("OK", comment: "OK"))
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 { hint = NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed") }
                else if code == 404 { hint = NSLocalizedString("ERR_ROUTE_HINT_ZHIPU", comment: "Route hint for Zhipu") }
                else if code == 429 { hint = NSLocalizedString("ERR_RATE_LIMITED", comment: "Rate limited") }
                else { hint = String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code) }
                let bodyText = body ?? ""
                return TestResult(status: .failure, message: bodyText.isEmpty ? hint : "\(hint): \(bodyText)")
            default:
                return TestResult(status: .failure, message: http.localizedDescription)
            }
        } catch { return TestResult(status: .failure, message: error.localizedDescription) }
    }

    func listModels(provider: Provider) async -> ([String], String?) {
        guard let (url, headers) = buildModelsURLAndHeaders(provider: provider) else {
            return ([], NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let client = HTTPClient(timeout: 8)
        do {
            let resp = try await client.get(url: url, headers: headers)
            if let obj = try? JSONSerialization.jsonObject(with: resp.data) as? [String: Any] {
                let arr = (obj["data"] as? [[String: Any]]) ?? (obj["models"] as? [[String: Any]]) ?? []
                let ids = arr.compactMap { item -> String? in
                    return (item["id"] as? String) ?? (item["name"] as? String) ?? (item["model"] as? String)
                }
                return ids.isEmpty ? ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) : (ids, nil)
            }
            return ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found"))
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
        } catch { return ([], error.localizedDescription) }
    }

    private func buildModelsURLAndHeaders(provider: Provider) -> (URL, [String: String])? {
        guard let base = URL(string: provider.baseURL) else { return nil }
        let trimmed = base.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url: URL
        if trimmed.hasSuffix("api/paas/v4") { url = base.appendingPathComponent("models") }
        else if trimmed.hasSuffix("api/paas") { url = base.appendingPathComponent("v4/models") }
        else { url = base.appendingPathComponent("api/paas/v4/models") }
        guard case let .bearer(keyRef) = provider.auth else { return nil }
        do {
            guard let k = try KeychainService.shared.read(account: keyRef) else { return nil }
            var headers = provider.extraHeaders
            headers["Authorization"] = "Bearer \(k)"
            return (url, headers)
        } catch { return nil }
    }
}

