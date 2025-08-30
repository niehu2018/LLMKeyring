import Foundation

struct HTTPResponse {
    let data: Data
    let response: HTTPURLResponse
}

enum HTTPError: Error, LocalizedError {
    case invalidURL
    case nonHTTPResponse
    case status(code: Int, body: String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .nonHTTPResponse: return "Non-HTTP response"
        case .status(let code, let body): return "HTTP \(code): \(body ?? "<no body>")"
        }
    }
}

final class HTTPClient {
    private let session: URLSession
    init(timeout: TimeInterval = 5) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }

    func get(url: URL, headers: [String: String]) async throws -> HTTPResponse {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        headers.forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw HTTPError.nonHTTPResponse }
        if (200..<300).contains(http.statusCode) {
            return HTTPResponse(data: data, response: http)
        } else {
            let body = String(data: data, encoding: .utf8)
            throw HTTPError.status(code: http.statusCode, body: body)
        }
    }
}

