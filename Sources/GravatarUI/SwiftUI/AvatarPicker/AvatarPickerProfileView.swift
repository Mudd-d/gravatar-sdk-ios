import Gravatar
import SwiftUI

@MainActor
struct AvatarPickerProfileView: View {
    private enum Constants {
        static let avatarLength: CGFloat = 72
    }

    struct Model {
        var displayName: String
        var location: String
        var profileURL: URL?
        var pronunciation: String
        var pronouns: String

        var profileDetails: String? {
            let joinedFields = [pronunciation, pronouns, location]
                .filter { !$0.isEmpty }
                .joined(separator: "・")
            return joinedFields.isEmpty ? nil : joinedFields
        }
    }

    @Binding var avatarID: AvatarIdentifier?
    private var avatarURL: URL? {
        guard let avatarID else { return nil }
        return AvatarURL(
            with: avatarID,
            options: .init(
                preferredSize: .points(Constants.avatarLength),
                defaultAvatarOption: .status404
            )
        )?.url
    }

    @Binding var forceRefreshAvatar: Bool
    @Binding var model: Model?
    @Binding var isLoading: Bool
    @StateObject private var placeholderColorManager: ProfileViewPlaceholderColorManager = .init()
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    private(set) var viewProfileAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: .DS.Padding.single) {
            avatarView()
            if model == nil && isLoading {
                emptyViews()
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(model?.displayName ?? Localized.namePlaceholder)
                        .font(.headline)
                        .fontWeight(.bold)
                    if let model {
                        if let details = model.profileDetails {
                            secondaryText(text: details)
                        }
                        Button(Localized.viewProfileButtonTitle) {
                            viewProfileAction?()
                        }
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.label))
                        .padding(.init(top: .DS.Padding.half, leading: 0, bottom: 0, trailing: 0))
                    } else {
                        secondaryText(text: Localized.profileDetailsPlaceholder)
                    }
                }
            }
        }
        .onChange(of: isLoading) { newValue in
            placeholderColorManager.toggleAnimation(newValue)
        }
        .onChange(of: colorScheme) { newValue in
            placeholderColorManager.colorScheme = newValue
        }
        .onAppear {
            placeholderColorManager.colorScheme = colorScheme
            placeholderColorManager.toggleAnimation(isLoading)
        }
    }

    private func secondaryText(text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(Color(UIColor.secondaryLabel))
    }

    func emptyViews() -> some View {
        VStack(alignment: .leading, spacing: .DS.Padding.half, content: {
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 180, height: 24)
            RoundedRectangle(cornerRadius: 6)
                .frame(width: 100, height: 12)
            RoundedRectangle(cornerRadius: 6)
                .frame(width: 140, height: 12)
        })
        .foregroundColor(placeholderColorManager.placeholderColor)
    }

    func avatarView() -> some View {
        AvatarView(
            url: avatarURL,
            placeholderView: {
                Image("qe-intro-empty-profile-avatar", bundle: .module)
                    .colorScheme(colorScheme)
                    .background(Color(UIColor.systemBackground))
            },
            forceRefresh: $forceRefreshAvatar,
            loadingView: {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        )
        .scaledToFill()
        .frame(width: Constants.avatarLength, height: Constants.avatarLength)
        .background(placeholderColorManager.placeholderColor)
        .aspectRatio(1, contentMode: .fill)
        .shape(Circle())
    }

    private var paletteType: PaletteType? {
        switch colorScheme {
        case .light:
            .light
        case .dark:
            .dark
        @unknown default:
            nil
        }
    }
}

// MARK: - Localized Strings

extension AvatarPickerProfileView {
    private enum Localized {
        static let viewProfileButtonTitle = SDKLocalizedString(
            "AvatarPickerProfile.Button.ViewProfile.title",
            value: "View profile →",
            comment: "Title of a button that will take you to your Gravatar profile, with an arrow indicating that this action will cause you to leave this view"
        )
        static let namePlaceholder = SDKLocalizedString(
            "AvatarPickerProfile.Name.placeholder",
            value: "Your Name",
            comment: "Placeholder text for the name field"
        )
        static let profileDetailsPlaceholder = SDKLocalizedString(
            "AvatarPickerProfile.ProfileFields.placeholder",
            value: "Job, location, pronouns etc.",
            comment: "Placeholder text for some profile fields."
        )
    }
}

// MARK: - Previews

#Preview {
    AvatarPickerProfileView(
        avatarID: .constant(.email("email@domain.com")),
        forceRefreshAvatar: .constant(false),
        model: .constant(
            .init(
                displayName: "Shelly Kimbrough",
                location: "San Antonio, TX",
                profileURL: URL(string: "https://gravatar.com"),
                pronunciation: "SHEL-ee",
                pronouns: "she/her"
            )
        ),
        isLoading: .constant(false)
    )
}

#Preview("Empty") {
    AvatarPickerProfileView(
        avatarID: .constant(.email("email@domain.com")),
        forceRefreshAvatar: .constant(false),
        model: .constant(nil),
        isLoading: .constant(false)
    )
}

#Preview("Empty & Loading") {
    AvatarPickerProfileView(
        avatarID: .constant(.email("email@domain.com")),
        forceRefreshAvatar: .constant(false),
        model: .constant(nil),
        isLoading: .constant(true)
    )
}
