import Foundation

final class BaiduQianfanAdapter: ProviderAdapter {
    // Baidu Qianfan (Wenxin)
    // Base: https://aip.baidubce.com
    // Health/List models (approx): GET /rpc/2.0/ai_custom/v1/wenxinworkshop/models?access_token=<token>
    // Auth: expects Keychain to store an access_token directly as the Bearer secret for simplicity.

    func testHealth(provider: Provider) async -> TestResult {
        guard let (url, headers) = buildModelsURLAndHeaders(provider: provider) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BAIDU_TOKEN_HINT", comment: "Baidu token hint"))
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
                else if code == 404 { hint = NSLocalizedString("ERR_ROUTE_HINT_BAIDU", comment: "Route hint for Baidu") }
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
            return ([], NSLocalizedString("ERR_BAIDU_TOKEN_HINT", comment: "Baidu token hint"))
        }
        let client = HTTPClient(timeout: 8)
        do {
            let resp = try await client.get(url: url, headers: headers)
            if let obj = try? JSONSerialization.jsonObject(with: resp.data) as? [String: Any] {
                let arr = (obj["data"] as? [[String: Any]]) ?? (obj["models"] as? [[String: Any]]) ?? []
                let ids = arr.compactMap { ($0["id"] as? String) ?? ($0["name"] as? String) ?? ($0["model"] as? String) }
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
        let url = base.appendingPathComponent("rpc/2.0/ai_custom/v1/wenxinworkshop/models")
        guard case let .bearer(keyRef) = provider.auth else { return nil }
        do {
            guard let token = try KeychainService.shared.read(account: keyRef) else { return nil }
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var items = comps?.queryItems ?? []
            items.append(URLQueryItem(name: "access_token", value: token))
            comps?.queryItems = items
            guard let final = comps?.url else { return nil }
            return (final, provider.extraHeaders)
        } catch { return nil }
    }
}

