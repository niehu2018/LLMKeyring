import Foundation

final class VertexGeminiAdapter: ProviderAdapter {
    // Google Cloud Vertex AI - Gemini
    // Expect Base URL like: https://us-central1-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/us-central1
    // Health/List models: GET {base}/publishers/google/models with Authorization: Bearer <access_token>

    func testHealth(provider: Provider) async -> TestResult {
        guard let (url, headers) = buildURLAndHeaders(provider: provider) else {
            return TestResult(status: .failure, message: NSLocalizedString("ERR_VERTEX_BASE_HINT", comment: "Vertex base hint"))
        }
        let client = HTTPClient(timeout: 8)
        do {
            _ = try await client.get(url: url, headers: headers)
            return TestResult(status: .success, message: NSLocalizedString("OK", comment: "OK"))
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 { hint = NSLocalizedString("ERR_VERTEX_AUTH_HINT", comment: "Vertex auth hint") }
                else { hint = String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code) }
                let bodyText = body ?? ""
                return TestResult(status: .failure, message: bodyText.isEmpty ? hint : "\(hint): \(bodyText)")
            default:
                return TestResult(status: .failure, message: http.localizedDescription)
            }
        } catch { return TestResult(status: .failure, message: error.localizedDescription) }
    }

    func listModels(provider: Provider) async -> ([String], String?) {
        guard let (url, headers) = buildURLAndHeaders(provider: provider) else {
            return ([], NSLocalizedString("ERR_VERTEX_BASE_HINT", comment: "Vertex base hint"))
        }
        let client = HTTPClient(timeout: 8)
        do {
            let resp = try await client.get(url: url, headers: headers)
            struct Resp: Decodable { struct Item: Decodable { let name: String }
                let models: [Item]? }
            let decoded = try JSONDecoder().decode(Resp.self, from: resp.data)
            let names = (decoded.models ?? []).map { $0.name }
            return names.isEmpty ? ([], NSLocalizedString("ERR_NO_MODELS_FOUND", comment: "No models found")) : (names, nil)
        } catch let http as HTTPError {
            switch http {
            case .status(let code, let body):
                let hint: String
                if code == 401 || code == 403 { hint = NSLocalizedString("ERR_VERTEX_AUTH_HINT", comment: "Vertex auth hint") }
                else { hint = String(format: NSLocalizedString("ERR_HTTP_CODE_FMT", comment: "HTTP code fmt"), code) }
                let bodyText = body ?? ""
                return ([], bodyText.isEmpty ? hint : "\(hint): \(bodyText)")
            default:
                return ([], http.localizedDescription)
            }
        } catch { return ([], error.localizedDescription) }
    }

    private func buildURLAndHeaders(provider: Provider) -> (URL, [String: String])? {
        guard let base = URL(string: provider.baseURL) else { return nil }
        let url = base.appendingPathComponent("publishers/google/models")
        guard case let .bearer(keyRef) = provider.auth else { return nil }
        do {
            guard let token = try KeychainService.shared.read(account: keyRef) else { return nil }
            var headers = provider.extraHeaders
            headers["Authorization"] = "Bearer \(token)"
            return (url, headers)
        } catch { return nil }
    }
}

