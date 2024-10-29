@preconcurrency import AuthenticationServices

final class WebAuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, Sendable {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

actor OldAuthenticationSession: Sendable {
    let context = WebAuthenticationPresentationContextProvider()
    var session: ASWebAuthenticationSession?

    func authenticate(using url: URL, callbackURLComponents: URLComponents) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            if #available(iOS 17.4, *) {
                let callback: ASWebAuthenticationSession.Callback = {
                    if callbackURLComponents.scheme == "https", let host = callbackURLComponents.host {
                        return .https(host: host, path: callbackURLComponents.path)
                    } else {
                        return .customScheme(callbackURLComponents.scheme ?? "")
                    }
                }()

                session = ASWebAuthenticationSession(url: url, callback: callback) { callbackURL, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let callbackURL {
                        continuation.resume(returning: callbackURL)
                    }
                }

            } else {
                session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLComponents.scheme) { callbackURL, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let callbackURL {
                        continuation.resume(returning: callbackURL)
                    }
                }
            }

            Task { @MainActor in
                await session?.presentationContextProvider = context
                await session?.start()
            }
        }
    }

    nonisolated
    func cancel() {
        Task { @MainActor in
            await session?.cancel()
        }
    }
}
