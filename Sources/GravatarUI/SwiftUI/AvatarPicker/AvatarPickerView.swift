import Gravatar
import SwiftUI

@MainActor
struct AvatarPickerView<ImageEditor: ImageEditorView>: View {
    fileprivate typealias Constants = AvatarPicker.Constants
    fileprivate typealias Localized = AvatarPicker.Localized

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Declare "@StateObject"s as private to prevent setting them from a
    // memberwise initializer, which can conflict with the storage
    // management that SwiftUI provides.
    // https://developer.apple.com/documentation/swiftui/stateobject
    @StateObject private var model: AvatarPickerViewModel
    @Binding var isPresented: Bool
    @Binding var authToken: String?

    @State private var safariURL: URL?
    @State private var uploadError: FailedUploadInfo?
    @State private var isUploadErrorDialogPresented: Bool = false
    @State private var shareSheetItem: AvatarShareItem?

    var contentLayoutProvider: AvatarPickerContentLayoutProviding
    var customImageEditor: ImageEditorBlock<ImageEditor>?
    var tokenErrorHandler: (() -> Void)?
    var avatarUpdatedHandler: (() -> Void)?

    init(
        email: Email,
        authToken: Binding<String?>,
        isPresented: Binding<Bool>,
        contentLayoutProvider: AvatarPickerContentLayoutProviding = AvatarPickerContentLayoutType.vertical,
        customImageEditor: ImageEditorBlock<ImageEditor>? = nil as NoCustomEditorBlock?,
        tokenErrorHandler: (() -> Void)? = nil,
        avatarUpdatedHandler: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.contentLayoutProvider = contentLayoutProvider
        self.customImageEditor = customImageEditor
        self.tokenErrorHandler = tokenErrorHandler
        self.avatarUpdatedHandler = avatarUpdatedHandler
        self._authToken = authToken
        self._model = StateObject(wrappedValue: AvatarPickerViewModel(email: email, authToken: authToken.wrappedValue))
    }

    fileprivate init(
        avatarImageModels: [AvatarImageModel],
        selectedImageID: String? = nil,
        profileModel: ProfileSummaryModel? = nil,
        isPresented: Binding<Bool>,
        contentLayoutProvider: AvatarPickerContentLayoutProviding = AvatarPickerContentLayoutType.vertical,
        customImageEditor: ImageEditorBlock<ImageEditor>? = nil as NoCustomEditorBlock?,
        tokenErrorHandler: (() -> Void)? = nil,
        avatarUpdatedHandler: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.contentLayoutProvider = contentLayoutProvider
        self.customImageEditor = customImageEditor
        self.tokenErrorHandler = tokenErrorHandler
        self.avatarUpdatedHandler = avatarUpdatedHandler
        self._authToken = .constant(nil)
        self._model = StateObject(
            wrappedValue: AvatarPickerViewModel(
                avatarImageModels: avatarImageModels,
                selectedImageID: selectedImageID,
                profileModel: profileModel
            )
        )
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                EmailText(email: model.email)
                    .accumulateIntrinsicHeight()
                profileView()
                    .accumulateIntrinsicHeight()
                ScrollView {
                    VStack(spacing: 0) {
                        errorView()
                        if !model.grid.isEmpty {
                            content()
                        } else if model.isAvatarsLoading {
                            avatarsLoadingView()
                        }
                        Spacer()
                            .frame(height: Constants.vStackVerticalSpacing)
                    }
                    .accumulateIntrinsicHeight()
                }
                .task {
                    model.refresh()
                }
                .confirmationDialog(
                    Localized.uploadErrorTitle,
                    isPresented: $isUploadErrorDialogPresented,
                    titleVisibility: .visible,
                    presenting: uploadError
                ) { error in
                    Button(role: .destructive) {
                        deleteFailedUpload(error.avatarLocalID)
                    } label: {
                        Label(Localized.removeButtonTitle, systemImage: "trash")
                    }
                    if error.supportsRetry {
                        Button {
                            retryUpload(error.avatarLocalID)
                        } label: {
                            Label(Localized.retryButtonTitle, systemImage: "arrow.clockwise")
                        }
                    }
                    Button(Localized.dismissButtonTitle, role: .cancel) {}
                } message: { error in
                    Text(error.errorMessage)
                }
            }

            ToastContainerView(toastManager: model.toastManager)
                .padding(.horizontal, Constants.horizontalPadding * 2)
        }
        .preference(key: VerticalSizeClassPreferenceKey.self, value: verticalSizeClass)
        .gravatarNavigation(
            title: Constants.title,
            actionButtonDisabled: model.profileModel?.profileURL == nil,
            onActionButtonPressed: {
                openProfileEditInSafari()
            },
            onDoneButtonPressed: {
                isPresented = false
            }
        )
        .fullScreenCover(item: $safariURL) { url in
            SafariView(url: url)
                .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: authToken ?? "") { newValue in
            model.update(authToken: newValue)
        }
        .onChange(of: model.backendSelectedAvatarURL) { _ in
            notifyAvatarSelection()
        }
        .sheet(item: $shareSheetItem) { item in
            // Sharing the url helps with proper metadata to appear at the top of the share sheet.
            // Plus, some apps may not prefer to define `NSPhotoLibraryAddUsageDescription` in such
            // cases the sharing can be done via opening the URL with Safari.
            ShareSheet(items: [item.url, item.image])
                .presentationDetentsIfAvailable([.medium, .large])
        }
    }

    private func header() -> some View {
        VStack(alignment: .leading) {
            Text(Localized.Header.title)
                .font(.title2.weight(.bold))
            Text(Localized.Header.subtitle)
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .padding(.init(top: .DS.Padding.double, leading: Constants.horizontalPadding, bottom: .DS.Padding.half, trailing: Constants.horizontalPadding))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorView() -> some View {
        VStack(alignment: .center) {
            switch model.gridResponseStatus {
            case .success where model.grid.isEmpty:
                contentLoadingErrorView(
                    title: Localized.ContentLoading.Success.title,
                    subtext: Localized.ContentLoading.Success.subtext,
                    image: Image("setup-avatar-emoji", bundle: .module),
                    actionButton: {
                        imagePicker {
                            CTAButtonView(Localized.buttonUploadImage)
                        }
                    }
                )
            case .failure(APIError.responseError(reason: let reason)) where reason.httpStatusCode == HTTPStatus.unauthorized.rawValue:
                let buttonTitle = tokenErrorHandler == nil ?
                    Localized.ContentLoading.Failure.SessionExpired.Close.buttonTitle :
                    Localized.ContentLoading.Failure.SessionExpired.LogIn.buttonTitle
                let subtext: String = tokenErrorHandler == nil ?
                    Localized.ContentLoading.Failure.SessionExpired.Close.subtext :
                    Localized.ContentLoading.Failure.SessionExpired.LogIn.subtext
                contentLoadingErrorView(
                    title: Localized.ContentLoading.Failure.SessionExpired.title,
                    subtext: subtext,
                    actionButton: {
                        Button {
                            if let tokenErrorHandler {
                                tokenErrorHandler()
                            } else {
                                isPresented = false
                            }
                        } label: {
                            CTAButtonView(buttonTitle)
                        }
                    }
                )
            case .failure(APIError.responseError(reason: let reason)) where reason.isURLSessionError:
                let subtext: String = if let reason = reason.urlSessionErrorLocalizedDescription {
                    reason
                } else {
                    Localized.ContentLoading.Failure.Retry.subtext
                }
                contentLoadingErrorView(
                    title: Localized.ContentLoading.Failure.Retry.title,
                    subtext: subtext,
                    actionButton: {
                        Button {
                            model.refresh()
                        } label: {
                            CTAButtonView(Localized.buttonRetry)
                        }
                    }
                )
            case .failure:
                contentLoadingErrorView(
                    title: Localized.ContentLoading.Failure.Retry.title,
                    subtext: Localized.ContentLoading.Failure.Retry.subtext,
                    image: nil,
                    actionButton: {
                        Button {
                            model.refresh()
                        } label: {
                            CTAButtonView(Localized.buttonRetry)
                        }
                    }
                )
            default:
                EmptyView()
            }
        }
        .foregroundColor(.secondary)
    }

    private func contentLoadingErrorView(
        title: String,
        subtext: String,
        image: Image? = nil,
        actionButton: @escaping () -> some View
    ) -> some View {
        ContentLoadingErrorView(
            title: title,
            subtext: subtext,
            image: image,
            actionButton: actionButton,
            innerPadding: .init(
                top: .DS.Padding.double,
                leading: Constants.horizontalPadding,
                bottom: .DS.Padding.double,
                trailing: Constants.horizontalPadding
            )
        )
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private func imagePicker(label: @escaping () -> some View) -> some View {
        SystemImagePickerView(label: label, customEditor: customImageEditor) { image in
            uploadImage(image)
        }
    }

    private func uploadImage(_ image: UIImage) {
        Task {
            // If there's a custom image editor, it should take care of squaring.
            await model.upload(image, shouldSquareImage: customImageEditor == nil)
        }
    }

    private func retryUpload(_ id: String) {
        Task {
            await model.retryUpload(of: id)
        }
    }

    private func deleteFailedUpload(_ id: String) {
        withAnimation {
            model.deleteFailed(id)
        }
    }

    @ViewBuilder
    private func avatarGrid() -> some View {
        // Even if the contentLayout is set to horizontal, we show vertical grid for large devices.
        // Because the system refuses to show a bottom sheet anyway and we end up with half empty horizontal content.
        if contentLayoutProvider.contentLayout == .vertical || horizontalSizeClass != .compact {
            AvatarGrid(
                grid: model.grid,
                customImageEditor: customImageEditor,
                onAvatarTap: { avatar in
                    selectAvatar(with: avatar.id)
                },
                onImagePickerDidPickImage: { image in
                    uploadImage(image)
                },
                onFailedUploadTapped: { failedUploadInfo in
                    uploadError = failedUploadInfo
                    isUploadErrorDialogPresented = true
                },
                onAvatarActionTap: { avatar, action in
                    handleAvatarAction(avatar: avatar, action: action)
                }
            )
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, .DS.Padding.medium)
        } else {
            HorizontalAvatarGrid(
                grid: model.grid,
                onAvatarTap: { avatar in
                    selectAvatar(with: avatar.id)
                },
                onFailedUploadTapped: { failedUploadInfo in
                    uploadError = failedUploadInfo
                    isUploadErrorDialogPresented = true
                },
                onAvatarActionTap: { avatar, action in
                    handleAvatarAction(avatar: avatar, action: action)
                }
            )
            .padding(.top, .DS.Padding.medium)
            .padding(.bottom, .DS.Padding.double)
            imagePicker {
                CTAButtonView(Localized.buttonUploadImage)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, .DS.Padding.medium)
        }
    }

    func handleAvatarAction(avatar: AvatarImageModel, action: AvatarAction) {
        switch action {
        case .share:
            Task {
                if let url = avatar.shareURL,
                    let image = await model.fetchOriginalSizeAvatar(for: avatar) {
                    shareSheetItem = AvatarShareItem(id: avatar.id, image: image, url: url)
                }
            }
        case .delete:
            // TODO: Delete
            break
        }
    }

    func selectAvatar(with id: String) {
        Task {
            if await model.selectAvatar(with: id) != nil {
                notifyAvatarSelection()
            }
        }
    }

    func notifyAvatarSelection() {
        if let avatarUpdatedHandler {
            // Delay to wait until the server has updated the selected avatar before updating the UI.
            // Without the delay the cache busting remains insufficient to capture the new avatar.
            // With less than 800 ms, we can still see the issue.
            // Hopefully, we can remove this delay soon.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                avatarUpdatedHandler()
            }
        }
    }

    private func content() -> some View {
        VStack(spacing: 0) {
            header()
            avatarGrid()
        }
        .avatarPickerBorder(colorScheme: colorScheme)
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private func avatarsLoadingView() -> some View {
        VStack {
            Spacer(minLength: .DS.Padding.large)

            ProgressView()
                .progressViewStyle(
                    CircularProgressViewStyle()
                )
                .controlSize(.regular)

            Spacer()
        }
    }

    private func openProfileInSafari() {
        safariURL = model.profileModel?.profileURL
    }

    private func openProfileEditInSafari() {
        guard let url = URL(string: "https://gravatar.com/profile") else { return }
        safariURL = url
    }

    @ViewBuilder
    private func profileView() -> some View {
        VStack(alignment: .leading, content: {
            AvatarPickerProfileView(
                avatarURL: $model.selectedAvatarURL,
                model: $model.profileModel,
                isLoading: $model.isProfileLoading
            ) {
                openProfileInSafari()
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.init(
                    top: .DS.Padding.single,
                    leading: Constants.horizontalPadding,
                    bottom: .DS.Padding.single,
                    trailing: Constants.horizontalPadding
                ))
                .background(profileBackground)
                .cornerRadius(8)
                .shadow(color: profileShadowColor, radius: profileShadowRadius, y: 3)
        })
        .padding(.top, Constants.profileViewTopSpacing / 2)
        .padding(.bottom, Constants.vStackVerticalSpacing)
        .padding(.horizontal, Constants.horizontalPadding)
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
        colorScheme == .light ? Constants.lightModeShadowColor : .clear
    }

    private var profileShadowRadius: CGFloat {
        colorScheme == .light ? 30 : 0
    }
}

// MARK: - Localized Strings

private enum AvatarPicker {
    enum Constants {
        static let horizontalPadding: CGFloat = .DS.Padding.double
        static let lightModeShadowColor = Color(uiColor: UIColor.rgba(25, 30, 35, alpha: 0.2))
        static let title: String = "Gravatar" // defined here to avoid translations
        static let vStackVerticalSpacing: CGFloat = .DS.Padding.medium
        static let profileViewTopSpacing: CGFloat = .DS.Padding.double
    }

    enum Localized {
        static let uploadErrorTitle = SDKLocalizedString(
            "AvatarPicker.Upload.Error.title",
            value: "Upload has failed",
            comment: "The title of the upload error dialog."
        )
        static let removeButtonTitle = SDKLocalizedString(
            "AvatarPicker.Upload.Error.Remove.title",
            value: "Remove",
            comment: "The title of the remove button on the upload error dialog."
        )
        static let retryButtonTitle = SDKLocalizedString(
            "AvatarPicker.Upload.Error.Retry.title",
            value: "Retry",
            comment: "The title of the retry button on the upload error dialog."
        )
        static let dismissButtonTitle = SDKLocalizedString(
            "AvatarPicker.Dismiss.title",
            value: "Dismiss",
            comment: "The title of the dismiss button on a confirmation dialog."
        )
        static let buttonUploadImage = SDKLocalizedString(
            "AvatarPicker.ContentLoading.Success.ctaButtonTitle",
            value: "Upload image",
            comment: "Title of a button that allow for uploading an image"
        )
        static let buttonRetry = SDKLocalizedString(
            "AvatarPicker.ContentLoading.Failure.Retry.ctaButtonTitle",
            value: "Try again",
            comment: "Title of a button that allows the user to try loading their avatars again"
        )

        enum Header {
            static let title = SDKLocalizedString(
                "AvatarPicker.Header.title",
                value: "Avatars",
                comment: "Title appearing in the header of a view that allows users to manage their avatars"
            )
            static let subtitle = SDKLocalizedString(
                "AvatarPicker.Header.subtitle",
                value: "Choose or upload your favorite avatar images and connect them to your email address.",
                comment: "A message describing the purpose of this view"
            )
        }

        enum ContentLoading {
            enum Success {
                static let title = SDKLocalizedString(
                    "AvatarPicker.ContentLoading.success.title",
                    value: "Let's setup your avatar",
                    comment: "Title of a message advising the user to setup their avatar"
                )
                static let subtext = SDKLocalizedString(
                    "AvatarPicker.ContentLoading.Success.subtext",
                    value: "Choose or upload your favorite avatar images and connect them to your email address.",
                    comment: "A message describing the actions a user can take to setup their avatar"
                )
            }

            enum Failure {
                enum SessionExpired {
                    static let title = SDKLocalizedString(
                        "AvatarPicker.ContentLoading.Failure.SessionExpired.title",
                        value: "Session expired",
                        comment: "Title of a message advising the user that their login session has expired."
                    )
                    enum Close {
                        static let buttonTitle = SDKLocalizedString(
                            "AvatarPicker.ContentLoading.Failure.SessionExpired.Close.buttonTitle",
                            value: "Close",
                            comment: "Title of a button that will close the Avatar Picker, appearing beneath a message that advises the user that their login session has expired."
                        )

                        static let subtext = SDKLocalizedString(
                            "AvatarPicker.ContentLoading.Failure.SessionExpired.Close.subtext",
                            value: "Sorry, it looks like your session has expired. Make sure you're logged in to update your Avatar.",
                            comment: "A message describing the error and advising the user to login again to resolve the issue"
                        )
                    }

                    enum LogIn {
                        static let buttonTitle = SDKLocalizedString(
                            "AvatarPicker.ContentLoading.Failure.SessionExpired.LogIn.buttonTitle",
                            value: "Log in",
                            comment: "Title of a button that will begin the process of authenticating the user, appearing beneath a message that advises the user that their login session has expired."
                        )
                        static let subtext = SDKLocalizedString(
                            "AvatarPicker.ContentLoading.Failure.SessionExpired.LogIn.subtext",
                            value: "Session expired for security reasons. Please log in to update your Avatar.",
                            comment: "A message describing the error and advising the user to login again to resolve the issue"
                        )
                    }
                }

                enum Retry {
                    static let title = SDKLocalizedString(
                        "AvatarPicker.ContentLoading.Failure.Retry.title",
                        value: "Ooops",
                        comment: "Title of a message advising the user that something went wrong while loading their avatars"
                    )
                    static let subtext = SDKLocalizedString(
                        "AvatarPicker.ContentLoading.Failure.Retry.subtext",
                        value: "Something went wrong and we couldn’t connect to Gravatar servers.",
                        comment: "A message asking the user to try again"
                    )
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Existing elements") {
    struct PreviewModel: ProfileSummaryModel {
        var avatarIdentifier: Gravatar.AvatarIdentifier? {
            .email("xxx@gmail.com")
        }

        var displayName: String {
            "Shelly Kimbrough"
        }

        var jobTitle: String {
            "Payroll clerk"
        }

        var pronunciation: String {
            "shell-ee"
        }

        var pronouns: String {
            "she/her"
        }

        var location: String {
            "San Antonio, TX"
        }

        var profileURL: URL? {
            URL(string: "https://gravatar.com")
        }

        var profileEditURL: URL? {
            URL(string: "https://gravatar.com")
        }
    }

    let avatarImageModels: [AvatarImageModel] = [
        .init(id: "0", source: .local(image: UIImage()), state: .loading),
        .init(id: "1", source: .remote(url: "https://gravatar.com/userimage/110207384/aa5f129a2ec75162cee9a1f0c472356a.jpeg?size=256")),
        .init(id: "2", source: .remote(url: "https://gravatar.com/userimage/110207384/db73834576b01b69dd8da1e29877ca07.jpeg?size=256")),
        .init(id: "3", source: .remote(url: "https://gravatar.com/userimage/110207384/3f7095bf2580265d1801d128c6410016.jpeg?size=256")),
        .init(id: "4", source: .remote(url: "https://gravatar.com/userimage/110207384/fbbd335e57862e19267679f19b4f9db8.jpeg?size=256")),
        .init(id: "5", source: .remote(url: "https://gravatar.com/userimage/110207384/96c6950d6d8ce8dd1177a77fe738101e.jpeg?size=256")),
        .init(id: "6", source: .remote(url: "https://gravatar.com/userimage/110207384/4a4f9385b0a6fa5c00342557a098f480.jpeg?size=256")),
        .init(id: "7", source: .local(image: UIImage()), state: .error(supportsRetry: true, errorMessage: "Something went wrong.")),
        .init(id: "8", source: .local(image: UIImage()), state: .error(supportsRetry: false, errorMessage: "Something went wrong.")),
    ]
    let selectedImageID = "5"
    let profileModel = PreviewModel()

    return AvatarPickerView<NoCustomEditor>(
        avatarImageModels: avatarImageModels,
        selectedImageID: selectedImageID,
        profileModel: profileModel,
        isPresented: .constant(true),
        contentLayoutProvider: AvatarPickerContentLayoutType.horizontal
    )
}

#Preview("Empty elements") {
    AvatarPickerView<NoCustomEditor>(avatarImageModels: [], profileModel: nil, isPresented: .constant(true))
}

#Preview("Load from network") {
    /// Enter valid email and auth token.
    AvatarPickerView<NoCustomEditor>(email: .init(""), authToken: .constant(""), isPresented: .constant(true))
}
