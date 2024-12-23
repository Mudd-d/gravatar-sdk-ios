import Foundation
import SwiftUI

struct AvatarPickerProfileViewWrapper: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @Binding var avatarURL: URL?
    @Binding var model: AvatarPickerProfileView.Model?
    @Binding var isLoading: Bool
    @Binding var safariURL: URL?

    public var body: some View {
        VStack(alignment: .leading, content: {
            AvatarPickerProfileView(
                avatarURL: $avatarURL,
                model: $model,
                isLoading: $isLoading
            ) {
                safariURL = model?.profileURL
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.init(
                    top: .DS.Padding.single,
                    leading: AvatarPicker.Constants.horizontalPadding,
                    bottom: .DS.Padding.single,
                    trailing: AvatarPicker.Constants.horizontalPadding
                ))
                .background(profileBackground)
                .cornerRadius(8)
                .shadow(color: profileShadowColor, radius: profileShadowRadius, y: 3)
        })
        .padding(.top, AvatarPicker.Constants.profileViewTopSpacing / 2)
        .padding(.bottom, AvatarPicker.Constants.vStackVerticalSpacing)
        .padding(.horizontal, AvatarPicker.Constants.horizontalPadding)
    }

    @ViewBuilder
    private var profileBackground: some View {
        if colorScheme == .dark {
            Color(UIColor.systemBackground).colorInvert().opacity(0.09)
        } else {
            Color(UIColor.systemBackground)
        }
    }

    private var profileShadowColor: Color {
        colorScheme == .light ? AvatarPicker.Constants.lightModeShadowColor : .clear
    }

    private var profileShadowRadius: CGFloat {
        colorScheme == .light ? 30 : 0
    }
}
