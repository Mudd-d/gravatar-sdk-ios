import Foundation

struct IdentifiableURL: Identifiable {
    let url: URL

    init?(url: URL?) { // for convenience
        guard let url else { return nil }
        self.url = url
    }

    public var id: String {
        url.absoluteString
    }
}
