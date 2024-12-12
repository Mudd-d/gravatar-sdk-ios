import SwiftUI

struct GravatarNavigationModifier: ViewModifier {
    var title: String?
    var doneButtonTitle: String?
    var actionButtonDisabled: Bool
    var shouldEmitInnerHeight: Bool

    @State private var safariURL: URL?

    var onActionButtonPressed: (() -> Void)? = nil
    var onDoneButtonPressed: (() -> Void)? = nil

    func body(content: Content) -> some View {
        content
            .navigationTitle(title ?? Constants.gravatarNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if let action = onActionButtonPressed {
                            action()
                        } else {
                            openProfileEditInSafari()
                        }
                    }) {
                        Image("gravatar", bundle: .module)
                            .tint(Color(UIColor.gravatarBlue))
                    }
                    .disabled(actionButtonDisabled)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        onDoneButtonPressed?()
                    }) {
                        Text(doneButtonTitle ?? Localized.doneButtonTitle)
                            .tint(Color(UIColor.gravatarBlue))
                    }
                }
            }
            .background {
                GeometryReader { geometry in
                    // This works to detect the navigation bar height.
                    // AFAIU, SwiftUI calculates the `safeAreaInsets.top` based on the actual visible content area.
                    // When a NavigationView is present, it accounts for the navigation bar being part of that system-provided safe area.
                    if shouldEmitInnerHeight {
                        Color.clear.preference(
                            key: InnerHeightPreferenceKey.self,
                            value: geometry.safeAreaInsets.top
                        )
                    }
                }
            }
            .fullScreenCover(item: $safariURL) { url in
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            }
    }

    private func openProfileEditInSafari() {
        guard let url = URL(string: "https://gravatar.com/profile") else { return }
        safariURL = url
    }
}

extension GravatarNavigationModifier {
    enum Constants {
        static let gravatarNavigationTitle = "Gravatar"
    }

    private enum Localized {
        static let doneButtonTitle = SDKLocalizedString(
            "GravatarNavigationModifier.Button.Done.title",
            value: "Done",
            comment: "Title of a button that closes the current view"
        )
    }
}

extension View {
    func gravatarNavigation(
        title: String? = nil,
        doneButtonTitle: String? = nil,
        actionButtonDisabled: Bool,
        shouldEmitInnerHeight: Bool = true,
        onActionButtonPressed: (() -> Void)? = nil,
        onDoneButtonPressed: (() -> Void)? = nil
    ) -> some View {
        modifier(
            GravatarNavigationModifier(
                title: title,
                doneButtonTitle: doneButtonTitle,
                actionButtonDisabled: actionButtonDisabled,
                shouldEmitInnerHeight: shouldEmitInnerHeight,
                onActionButtonPressed: onActionButtonPressed,
                onDoneButtonPressed: onDoneButtonPressed
            )
        )
    }
}
