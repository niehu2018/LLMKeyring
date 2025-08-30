import Foundation

final class OllamaAdapter: ProviderAdapter {
    func testHealth(provider: Provider) async -> TestResult {
        guard let base = URL(string: provider.baseURL) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let primary = base.appendingPathComponent("api/tags")
        var candidates: [URL] = []
        if var comps = URLComponents(url: primary, resolvingAgainstBaseURL: false),
           comps.host == "localhost" || comps.host == "::1" {
            comps.host = "127.0.0.1"
            if let ipv4 = comps.url { candidates.append(ipv4) } // prefer IPv4 first
        }
        candidates.append(primary)
        guard !candidates.isEmpty else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let client = HTTPClient(timeout: 5)
        var lastError: String?
        for url in candidates {
            do {
                _ = try await client.get(url: url, headers: provider.extraHeaders)
                return TestResult(status: .success, message: NSLocalizedString("OK", comment: "OK"))
            } catch let http as HTTPError {
                switch http {
                case .status(let code, let body):
                    let hint = (code == 404)
                        ? NSLocalizedString("ERR_ROUTE_HINT_OLLAMA", comment: "Ollama route hint")
                        : String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code)
                    let bodyText = body ?? ""
                    lastError = bodyText.isEmpty ? hint : "\(hint): \(bodyText)"
                    break
                default:
                    lastError = http.localizedDescription
                }
            } catch {
                lastError = error.localizedDescription
            }
        }
        let advice = NSLocalizedString("ERR_OLLAMA_LOCALHOST_IPV6_HINT", comment: "Ollama localhost IPv6 hint")
        let message = [lastError, advice].compactMap { $0 }.joined(separator: "\n")
        return TestResult(status: .failure, message: message)
    }

    func listModels(provider: Provider) async -> ([String], String?) {
        guard let base = URL(string: provider.baseURL) else {
            return ([], NSLocalizedString("ERR_BASE_URL_INVALID", comment: "Base URL invalid"))
        }
        let primary = base.appendingPathComponent("api/tags")
        var candidates: [URL] = []
        if var comps = URLComponents(url: primary, resolvingAgainstBaseURL: false),
           comps.host == "localhost" || comps.host == "::1" {
            comps.host = "127.0.0.1"
            if let ipv4 = comps.url { candidates.append(ipv4) } // prefer IPv4 first
        }
        candidates.append(primary)
        let client = HTTPClient(timeout: 5)
        var lastError: String?
        for url in candidates {
            do {
                let resp = try await client.get(url: url, headers: provider.extraHeaders)
                struct Tags: Decodable { struct Item: Decodable { let name: String?; let model: String? }
                    let models: [Item]? }
                let tags = (try? JSONDecoder().decode(Tags.self, from: resp.data))
                let names = tags?.models?.compactMap { $0.name ?? $0.model } ?? []
                if names.isEmpty { return ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) }
                return (names, nil)
            } catch let http as HTTPError {
                switch http {
                case .status(let code, let body):
                    let hint = (code == 404)
                        ? NSLocalizedString("ERR_ROUTE_HINT_OLLAMA", comment: "Ollama route hint")
                        : String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code)
                    let bodyText = body ?? ""
                    lastError = bodyText.isEmpty ? hint : "\(hint): \(bodyText)"
                default:
                    lastError = http.localizedDescription
                }
            } catch {
                lastError = error.localizedDescription
            }
        }
        let advice = NSLocalizedString("ERR_OLLAMA_LOCALHOST_IPV6_HINT", comment: "Ollama localhost IPv6 hint")
        let message = [lastError, advice].compactMap { $0 }.joined(separator: "\n")
        return ([], message)
    }
}
