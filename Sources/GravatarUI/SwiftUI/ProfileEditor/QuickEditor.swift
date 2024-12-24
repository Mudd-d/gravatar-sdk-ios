import Gravatar
import SwiftUI

@available(iOS, deprecated: 16.0, renamed: "QuickEditorScope")
public enum QuickEditorScopeType: Sendable {
    case avatarPicker
}

public enum QuickEditorScope: Sendable {
    case avatarPicker(AvatarPickerConfiguration)

    var scopeType: QuickEditorScopeType {
        switch self {
        case .avatarPicker:
            .avatarPicker
        }
    }
}

struct QuickEditor<ImageEditor: ImageEditorView>: View {
    fileprivate typealias Constants = QuickEditorConstants

    @Environment(\.oauthSession) private var oauthSession
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State private var fetchedToken: String?
    @State private var isAuthenticating: Bool = true
    @State private var oauthError: OAuthError?
    @State private var safariURL: URL?
    @Binding private var isPresented: Bool
    // Declare "@StateObject"s as private to prevent setting them from a
    // memberwise initializer, which can conflict with the storage
    // management that SwiftUI provides.
    // https://developer.apple.com/documentation/swiftui/stateobject
    @StateObject private var model: AvatarPickerViewModel

    private let externalToken: String?
    private var token: String? { externalToken ?? fetchedToken }
    private let scope: QuickEditorScopeType
    private let email: Email
    private let customImageEditor: ImageEditorBlock<ImageEditor>?
    private let contentLayoutProvider: AvatarPickerContentLayoutProviding
    private let avatarUpdatedHandler: (() -> Void)?

    init(
        email: Email,
        scope: QuickEditorScopeType,
        token: String? = nil,
        isPresented: Binding<Bool>,
        customImageEditor: ImageEditorBlock<ImageEditor>? = nil,
        contentLayoutProvider: AvatarPickerContentLayoutProviding = AvatarPickerContentLayoutType.vertical,
        avatarUpdatedHandler: (() -> Void)? = nil
    ) {
        self.email = email
        self.scope = scope
        self._isPresented = isPresented
        self.customImageEditor = customImageEditor
        self.contentLayoutProvider = contentLayoutProvider
        self.externalToken = token
        self.avatarUpdatedHandler = avatarUpdatedHandler
        self._model = StateObject(wrappedValue: AvatarPickerViewModel(email: email, authToken: token))
    }

    let authorizationFinishedNotification = NotificationCenter.default.publisher(for: .authorizationFinished)
    let authorizationErrorNotification = NotificationCenter.default.publisher(for: .authorizationError)

    var body: some View {
        NavigationView {
            if let token {
                editorView(with: token)
            } else {
                noticeView()
            }
        }.onReceive(authorizationFinishedNotification) { _ in
            onAuthenticationFinished()
        }.onReceive(authorizationErrorNotification) { notification in
            guard let error = notification.object as? OAuthError else { return }
            oauthError = error
            onAuthenticationFinished()
        }
        .onChange(of: token) { newValue in
            if let newValue {
                model.update(authToken: newValue)
            }
        }
    }

    @MainActor
    func editorView(with token: String) -> some View {
        switch scope {
        case .avatarPicker:
            AvatarPickerView(
                model: model,
                isPresented: $isPresented,
                contentLayoutProvider: contentLayoutProvider,
                customImageEditor: customImageEditor,
                tokenErrorHandler: externalToken != nil ? nil : {
                    oauthSession.markSessionAsExpired(with: email)
                    performAuthentication()
                },
                avatarUpdatedHandler: avatarUpdatedHandler
            )
        }
    }

    @MainActor
    func noticeView() -> some View {
        VStack(spacing: 0) {
            if !isAuthenticating {
                VStack(spacing: 0) {
                    EmailText(email: email)
                    if shouldShowIntro {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(QuickEditorConstants.Localized.MissingToken.headline)
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(Color(UIColor.label))

                            Text(String(format: QuickEditorConstants.Localized.MissingToken.subheadline, BundleInfo.appName ?? ""))
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.top, .DS.Padding.half)
                        }
                        .padding(.top, .DS.Padding.split)
                        .padding(.bottom, .DS.Padding.split)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    AvatarPickerProfileViewWrapper(
                        avatarURL: $model.selectedAvatarURL,
                        model: $model.profileModel,
                        isLoading: $model.isProfileLoading,
                        safariURL: $safariURL
                    )
                    .padding(.top, AvatarPicker.Constants.profileViewTopSpacing / 2)
                    .padding(.bottom, AvatarPicker.Constants.vStackVerticalSpacing)
                    ContentLoadingErrorView(
                        title: Constants.ErrorView.title(for: oauthError),
                        subtext: Constants.ErrorView.subtext(for: oauthError),
                        image: nil,
                        actionButton: {
                            Button {
                                performAuthentication()
                            } label: {
                                CTAButtonView(Constants.ErrorView.buttonTitle(for: oauthError))
                            }
                        },
                        innerPadding: .init(
                            top: .DS.Padding.double,
                            leading: .DS.Padding.double,
                            bottom: .DS.Padding.double,
                            trailing: .DS.Padding.double
                        )
                    )
                    .padding(.bottom, .DS.Padding.double)
                }
                .padding(.horizontal, AvatarPicker.Constants.horizontalPadding)
                .accumulateIntrinsicHeight()

                // We don't want to include this into intrinsic height calculation so not adding `.accumulateIntrinsicHeight()` here.
                Spacer(minLength: 0)
            } else {
                ProgressView()
                    .accumulateIntrinsicHeight()
            }
        }
        .gravatarNavigation(
            actionButtonDisabled: model.profileModel?.profileURL == nil,
            onDoneButtonPressed: {
                isPresented = false
            },
            preferenceKey: InnerHeightPreferenceKey.self
        )
        .presentSafariView(url: $safariURL, colorScheme: colorScheme)
        .task(id: email) {
            await model.fetchProfile()
        }
        .task {
            performAuthentication()
        }
    }

    @MainActor
    func performAuthentication() {
        Task {
            isAuthenticating = true
            if !oauthSession.hasValidSession(with: email) {
                do {
                    try await oauthSession.retrieveAccessToken(with: email)
                } catch OAuthError.oauthResponseError(_, let code) where code == .canceledLogin {
                    // ignore the error if the user has cancelled the operation.
                } catch let error as OAuthError {
                    oauthError = error
                } catch {
                    oauthError = nil
                }
            }
            onAuthenticationFinished()
        }
    }

    func onAuthenticationFinished() {
        if let fetchedToken = oauthSession.sessionToken(with: email)?.token {
            self.fetchedToken = fetchedToken
            oauthError = nil
        }
        isAuthenticating = false
    }

    var shouldShowIntro: Bool {
        switch oauthError {
        case .loggedInWithWrongEmail:
            false
        default:
            token == nil
        }
    }
}

enum QuickEditorConstants {
    enum ErrorView {
        static func title(for oauthError: OAuthError?) -> String? {
            switch oauthError {
            case .loggedInWithWrongEmail:
                Localized.WrongEmailError.title
            default:
                nil
            }
        }

        static func subtext(for oauthError: OAuthError?) -> String {
            switch oauthError {
            case .loggedInWithWrongEmail(let email):
                String(format: Localized.WrongEmailError.subtext, email)
            default:
                Localized.MissingToken.subtext
            }
        }

        static func buttonTitle(for oauthError: OAuthError?) -> String {
            Localized.MissingToken.buttonTitle
        }
    }

    enum Localized {
        enum WrongEmailError {
            static let title = SDKLocalizedString(
                "AvatarPicker.ContentLoading.Failure.Retry.title",
                value: "Ooops",
                comment: "Title of a message advising the user that something went wrong while loading their avatars"
            )
            static let subtext = SDKLocalizedString(
                "AvatarPicker.ContentLoading.Failure.WrongEmailError.subtext",
                value: "It looks like you used the wrong email to log in. Please try again using %@ this time. Thanks!",
                comment: "A message describing the error and advising the user to login again to resolve the issue"
            )
        }

        enum MissingToken {
            static let headline = SDKLocalizedString(
                "AvatarPicker.ContentLoading.Failure.MissingToken.headline",
                value: "Edit your Profile",
                comment: "Headline of an intro screen for editing a user's profile."
            )

            static let subheadline = SDKLocalizedString(
                "AvatarPicker.ContentLoading.Failure.MissingToken.subheadline",
                value: "Enhance your %@ profile with Gravatar.",
                comment: "Subheadline of an intro screen for editing a user's profile. %@ is the name of a mobile app that uses Gravatar services."
            )

            static let buttonTitle = SDKLocalizedString(
                "AvatarPicker.Continue.title",
                value: "Continue",
                comment: "Title of a button that will proceed with the action."
            )

            static let subtext = SDKLocalizedString(
                "AvatarPicker.ContentLoading.Failure.MissingToken.subtext",
                value: "Manage your profile for the web in one place.",
                comment: "A message that informs the user about Gravatar."
            )
        }
    }
}

#Preview {
    QuickEditor<NoCustomEditor>(
        email: .init(""),
        scope: .avatarPicker,
        isPresented: .constant(true),
        contentLayoutProvider: AvatarPickerContentLayout.vertical(presentationStyle: .large)
    )
}
