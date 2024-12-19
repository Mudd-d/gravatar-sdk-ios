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
    @State private var fetchedToken: String?
    @State private var isAuthenticating: Bool = true
    @State private var oauthError: OAuthError?
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
                    .accumulateIntrinsicHeight()
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
        VStack {
            if !isAuthenticating {
                EmailText(email: email)
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
                .padding(.horizontal, .DS.Padding.double)
                Spacer()
            } else {
                ProgressView()
            }
        }.gravatarNavigation(
            actionButtonDisabled: true,
            onDoneButtonPressed: {
                isPresented = false
            },
            preferenceKey: InnerHeightPreferenceKey.self
        )
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
}

enum QuickEditorConstants {
    enum ErrorView {
        static func title(for oauthError: OAuthError?) -> String {
            switch oauthError {
            case .loggedInWithWrongEmail:
                Localized.WrongEmailError.title
            default:
                Localized.LogInError.title
            }
        }

        static func subtext(for oauthError: OAuthError?) -> String {
            switch oauthError {
            case .loggedInWithWrongEmail(let email):
                String(format: Localized.WrongEmailError.subtext, email)
            default:
                Localized.LogInError.subtext
            }
        }

        static func buttonTitle(for oauthError: OAuthError?) -> String {
            Localized.LogInError.buttonTitle
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

        enum LogInError {
            static let title = SDKLocalizedString(
                "AvatarPicker.ContentLoading.Failure.LogInError.title",
                value: "Login required",
                comment: "Title of a message advising the user that something went wrong while trying to log in."
            )

            static let buttonTitle = SDKLocalizedString(
                "AvatarPicker.ContentLoading.Failure.SessionExpired.LogInError.buttonTitle",
                value: "Log in",
                comment: "Title of a button that will begin the process of authenticating the user, appearing beneath a message stating that a previous log in attept has failed."
            )

            static let subtext = SDKLocalizedString(
                "AvatarPicker.ContentLoading.Failure.SessionExpired.LogInError.subtext",
                value: "To modify your Gravatar profile, you need to log in first.",
                comment: "A message describing the error and advising the user to login again to resolve the issue"
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
