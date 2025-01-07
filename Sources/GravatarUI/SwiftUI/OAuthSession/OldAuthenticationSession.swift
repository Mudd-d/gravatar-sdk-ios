@preconcurrency import AuthenticationServices

extension OldAuthenticationSession: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

final class OldAuthenticationSession: NSObject, Sendable {
    private let sessionStorage = SessionStorage()

    func authenticate(using url: URL, callbackURLComponents: URLComponents) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session: ASWebAuthenticationSession
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

            Task {
                await sessionStorage.save(session)
            }

            Task { @MainActor in
                guard let session = await sessionStorage.restore() else { return }
                session.presentationContextProvider = self
                session.start()
            }
        }
    }

    func cancel() {
        Task { @MainActor in
            guard let session = await sessionStorage.restore() else { return }
            session.cancel()
        }
    }
}

// `ASWebAuthenticationSession` is not thread safe. `SessionStorage` helps to silence some warnings (Swift 6 errors),
// but we are still importing `AuthenticationServices` as `@preconcurrency`.
// In the other hand, there won't be more than one attempt of oauth at a time, which reduces possible concurrency issues.
private actor SessionStorage {
    var current: ASWebAuthenticationSession?

    func save(_ session: ASWebAuthenticationSession) {
        current = session
    }

    func restore() -> ASWebAuthenticationSession? {
        let currentSession = current
        return currentSession
    }
}
