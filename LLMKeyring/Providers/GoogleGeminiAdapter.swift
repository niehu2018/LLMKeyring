import Foundation

final class GoogleGeminiAdapter: ProviderAdapter {
    // Google Generative Language (Gemini)
    // Base: https://generativelanguage.googleapis.com
    // Models: GET /v1/models?key=API_KEY

    func testHealth(provider: Provider) async -> TestResult {
        guard let (url, headers) = buildModelsURLAndHeaders(provider: provider) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let client = HTTPClient(timeout: 6)
        do {
            _ = try await client.get(url: url, headers: headers)
            return TestResult(status: .success, message: NSLocalizedString("OK", comment: "OK"))
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String = (code == 401 || code == 403)
                    ? NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed")
                    : String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code)
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
        guard let (url, headers) = buildModelsURLAndHeaders(provider: provider) else {
            return ([], NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let client = HTTPClient(timeout: 6)
        do {
            let resp = try await client.get(url: url, headers: headers)
            struct Resp: Decodable { struct Item: Decodable { let name: String }
                let models: [Item]?; let data: [Item]? }
            let decoded = try JSONDecoder().decode(Resp.self, from: resp.data)
            let items = decoded.models ?? decoded.data ?? []
            let names = items.map { $0.name }
            return names.isEmpty ? ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) : (names, nil)
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String = (code == 401 || code == 403)
                    ? NSLocalizedString("ERR_AUTH_FAILED_HINT", comment: "Auth failed")
                    : String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code)
                let bodyText = body ?? ""
                return ([], bodyText.isEmpty ? hint : "\(hint): \(bodyText)")
            default:
                return ([], http.localizedDescription)
            }
        } catch {
            return ([], error.localizedDescription)
        }
    }

    private func buildModelsURLAndHeaders(provider: Provider) -> (URL, [String: String])? {
        guard let base = URL(string: provider.baseURL) else { return nil }
        var url: URL
        let trimmed = base.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.hasSuffix("v1") { url = base.appendingPathComponent("models") }
        else { url = base.appendingPathComponent("v1/models") }

        guard case let .bearer(keyRef) = provider.auth else { return nil }
        do {
            guard let k = try KeychainService.shared.read(account: keyRef) else { return nil }
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var items = comps?.queryItems ?? []
            items.append(URLQueryItem(name: "key", value: k))
            comps?.queryItems = items
            if let final = comps?.url {
                return (final, provider.extraHeaders)
            } else { return nil }
        } catch { return nil }
    }
}

