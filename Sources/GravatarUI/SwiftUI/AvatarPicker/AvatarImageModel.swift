import SwiftUI
import UIKit

struct AvatarImageModel: Hashable, Identifiable, Sendable {
    enum Source: Hashable {
        case remote(url: String)
        case local(image: UIImage)
    }

    enum State: Equatable, Hashable {
        case loaded
        case loading
        case error(supportsRetry: Bool, errorMessage: String)
    }

    let id: String
    let source: Source
    let isSelected: Bool
    let state: State
    let altText: String
    let rating: AvatarRating

    var url: URL? {
        guard case .remote(let url) = source else {
            return nil
        }
        return URL(string: url)
    }

    var shareURL: URL? {
        guard case .remote(let url) = source else {
            return nil
        }
        return URLComponents(string: url)?.replacingQueryItem(name: "size", value: "max").url
    }

    var localImage: Image? {
        guard case .local(let image) = source else {
            return nil
        }
        return Image(uiImage: image)
    }

    var localUIImage: UIImage? {
        guard case .local(let image) = source else {
            return nil
        }
        return image
    }

    init(id: String, source: Source, state: State = .loaded, isSelected: Bool = false, rating: AvatarRating = .g, altText: String = "") {
        self.id = id
        self.source = source
        self.state = state
        self.isSelected = isSelected
        self.rating = rating
        self.altText = altText
    }

    func settingStatus(to newStatus: State) -> AvatarImageModel {
        AvatarImageModel(id: id, source: source, state: newStatus, isSelected: isSelected, rating: rating, altText: altText)
    }
}
