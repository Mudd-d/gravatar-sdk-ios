import Foundation
import SwiftUI

enum AvatarAction: String, CaseIterable, Identifiable {
    case share
    case delete
    case playground
    case altText

    static var allCases: [AvatarAction] {
        var cases: [AvatarAction] = []
        if #available(iOS 18.2, *) {
            if EnvironmentValues().supportsImagePlayground {
                cases.append(.playground)
            }
        }
        cases.append(contentsOf: [.share, .altText, .delete])
        return cases
    }

    var id: String { rawValue }

    var icon: Image {
        switch self {
        case .delete:
            Image(systemName: "trash")
        case .share:
            Image(systemName: "square.and.arrow.up")
        case .playground:
            Image(systemName: "apple.image.playground")
        case .altText:
            Image(systemName: "text.below.photo")
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
        case .altText:
            SDKLocalizedString(
                "AvatarPicker.AvatarAction.altText",
                value: "Alt Text",
                comment: "An option in the avatar menu that edits the avatar's Alt Text."
            )
        }
    }

    var role: ButtonRole? {
        switch self {
        case .delete:
            .destructive
        case .share, .playground, .altText:
            nil
        }
    }
}
