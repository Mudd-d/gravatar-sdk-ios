import Foundation
import SwiftUI

enum AvatarAction: Identifiable {
    case share
    case delete
    case rating(AvatarRating)
    case playground

    var id: String {
        switch self {
        case .share: "share"
        case .delete: "delete"
        case .rating(let rating): rating.rawValue
        case .playground: "playground"
        }
    }

    var icon: Image {
        switch self {
        case .delete:
            Image(systemName: "trash")
        case .share:
            Image(systemName: "square.and.arrow.up")
        case .playground:
            Image(systemName: "apple.image.playground")
        case .rating:
            Image(systemName: "star.leadinghalf.filled")
        }
    }

    var localizedTitle: String {
        switch self {
        case .delete:
            SDKLocalizedString(
                "AvatarPicker.AvatarAction.delete",
                value: "Delete",
                comment: "An option in the avatar menu that deletes the avatar"
            )
        case .share:
            SDKLocalizedString(
                "AvatarPicker.AvatarAction.share",
                value: "Share...",
                comment: "An option in the avatar menu that shares the avatar"
            )
        case .playground:
            SDKLocalizedString(
                "SystemImagePickerView.Source.Playground.title",
                value: "Playground",
                comment: "An option to show the image playground"
            )
        case .rating(let rating):
            String(
                format: SDKLocalizedString(
                    "AvatarPicker.AvatarAction.rate",
                    value: "Rating: %@",
                    comment: "An option in the avatar menu that shows the current rating, and allows the user to change that rating. The rating is used to indicate the appropriateness of an avatar for different audiences, and follows the US system of Motion Picture ratings: G, PG, R, and X."
                ),
                rating.rawValue
            )
        }
    }

    var role: ButtonRole? {
        switch self {
        case .delete:
            .destructive
        case .share, .rating, .playground:
            nil
        }
    }
}
