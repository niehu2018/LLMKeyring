import Foundation

final class AliyunDashScopeAdapter: ProviderAdapter {
    // Native DashScope base, e.g. https://dashscope.aliyuncs.com
    // Model list: GET /api/v1/models (Authorization: Bearer <key>)

    func testHealth(provider: Provider) async -> TestResult {
        guard let base = URL(string: provider.baseURL) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let url = normalize(base: base)
        var headers = provider.extraHeaders
        if case let .bearer(keyRef) = provider.auth {
            do {
                guard let k = try KeychainService.shared.read(account: keyRef) else {
                    return TestResult(status: .failure, message: NSLocalizedString("ERR_KEYCHAIN_MISSING", comment: "Keychain credential missing"))
                }
                headers["Authorization"] = "Bearer \(k)"
            } catch {
                return TestResult(status: .failure, message: error.localizedDescription)
            }
        } else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed hint"))
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
                    hint = String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code)
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
        let url = normalize(base: base)
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
        } else {
            return ([], NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed hint"))
        }
        let client = HTTPClient(timeout: 8)
        do {
            let resp = try await client.get(url: url, headers: headers)
            // Accept several possible shapes: {data:[{id|name|model:...}]}, or {models:[...]}, or top-level array
            if let arr = try? JSONSerialization.jsonObject(with: resp.data) as? [[String: Any]] {
                let ids = extractIDs(fromItems: arr)
                return ids.isEmpty ? ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) : (ids, nil)
            } else if let obj = try? JSONSerialization.jsonObject(with: resp.data) as? [String: Any] {
                let candidates: [[String: Any]] = (obj["data"] as? [[String: Any]]) ?? (obj["models"] as? [[String: Any]]) ?? []
                let ids = extractIDs(fromItems: candidates)
                return ids.isEmpty ? ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) : (ids, nil)
            } else {
                return ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found"))
            }
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 { hint = NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed") }
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

    private func extractIDs(fromItems items: [[String: Any]]) -> [String] {
        var out: [String] = []
        for it in items {
            if let s = it["id"] as? String { out.append(s); continue }
            if let s = it["name"] as? String { out.append(s); continue }
            if let s = it["model"] as? String { out.append(s); continue }
        }
        return out
    }

    private func normalize(base: URL) -> URL {
        // Accept bases like:
        // - https://dashscope.aliyuncs.com
        // - https://dashscope.aliyuncs.com/api
        // - https://dashscope.aliyuncs.com/api/v1
        // and resolve to .../api/v1/models exactly once
        let trimmed = base.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.hasSuffix("api/v1") {
            return base.appendingPathComponent("models")
        } else if trimmed.hasSuffix("api") {
            return base.appendingPathComponent("v1/models")
        } else {
            return base.appendingPathComponent("api/v1/models")
        }
    }
}
