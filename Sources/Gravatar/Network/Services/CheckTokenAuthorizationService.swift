import Foundation

package struct CheckTokenAuthorizationService: Sendable {
    private let client: HTTPClient

    package init(session: URLSessionProtocol? = nil) {
        self.client = URLSessionHTTPClient(urlSession: session)
    }

    /// Checks if the given access token is authorized to make changes to this Gravatar account.
    /// - Parameters:
    ///   - token: WordPress.com access token.
    ///   - email: Email to check.
    package func isToken(_ token: String, authorizedFor email: Email) async throws -> Bool {
        var urlComponents = APIConfig.baseURLComponents
        urlComponents.path = "/v3/me/associated-email"
        urlComponents.queryItems = [
            URLQueryItem(name: "email_hash", value: email.hashID.id),
        ]
        guard let url = urlComponents.url else {
            throw APIError.requestError(reason: .urlInitializationFailed)
        }
        var request = URLRequest(url: url).settingAuthorizationHeaderField(with: token)
        request.httpMethod = "GET"
        do {
            let (data, _) = try await client.data(with: request)
            let result: AssociatedResponse = try data.decode()
            return result.associated
        } catch {
            throw error.apiError()
        }
    }
}
