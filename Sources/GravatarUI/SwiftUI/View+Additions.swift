import SwiftUI

@MainActor
extension View {
    public func shape(_ shape: some Shape, borderColor: Color = .clear, borderWidth: CGFloat = 0) -> some View {
        self
            .clipShape(shape)
            .overlay(
                shape
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    func avatarPickerBorder(colorScheme: ColorScheme, borderWidth: CGFloat = 1) -> some View {
        self
            .shape(
                RoundedRectangle(cornerRadius: 8),
                borderColor: Color(UIColor.label).opacity(colorScheme == .dark ? 0.16 : 0.08),
                borderWidth: borderWidth
            )
            .padding(.vertical, borderWidth) // to prevent borders from getting clipped
    }

    /// A modifier to display the QuickEditor sheet. QuickEditor can be used to select and upload a new avatar.
    /// - Parameters:
    ///   - isPresented: A Binding boolean to manage showing/hiding the sheet.
    ///   - email: Email for the Gravatar account.
    ///   - authToken: (Optional) Gravatar OAuth token. If not passed, Gravatar OAuth flow will start to gather the token internally.
    ///   Pass this only if your app already has a Gravatar OAuth token.
    ///   - scope: Scope for the QuickEditor.
    ///   - customImageEditor: (Optional) A custom image editor to show the user right after an image is picked for
    ///   cropping and other sorts of image editing operations.
    ///   - avatarUpdatedHandler: (Optional) A callback to execute when a different avatar is selected.
    ///   - onDismiss: (Optional) A callback to execute when the sheet is dismissed.
    /// - Returns: A modifier to display the QuickEditor sheet.
    @available(iOS, deprecated: 16.0, message: "Use the new method that takes in `QuickEditorScope`.")
    public func gravatarQuickEditorSheet(
        isPresented: Binding<Bool>,
        email: String,
        authToken: String? = nil,
        scope: QuickEditorScopeType,
        customImageEditor: ImageEditorBlock<some ImageEditorView>? = nil as NoCustomEditorBlock?,
        avatarUpdatedHandler: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        let editor = QuickEditor(
            email: .init(email),
            scope: scope,
            token: authToken,
            isPresented: isPresented,
            customImageEditor: customImageEditor,
            contentLayoutProvider: AvatarPickerContentLayoutType.vertical,
            avatarUpdatedHandler: avatarUpdatedHandler
        )
        return modifier(ModalPresentationModifier(isPresented: isPresented, onDismiss: onDismiss, modalView: editor))
    }

    /// A modifier to display the QuickEditor sheet. QuickEditor can be used to select and upload a new avatar.
    /// - Parameters:
    ///   - isPresented: A Binding boolean to manage showing/hiding the sheet.
    ///   - email: Email for the Gravatar account.
    ///   - authToken: (Optional) Gravatar OAuth token. If not passed, Gravatar OAuth flow will start to gather the token internally.
    ///   Pass this only if your app already has a Gravatar OAuth token.
    ///   - scope: Scope for the QuickEditor. See: ``QuickEditorScope``.
    ///   - customImageEditor: (Optional) A custom image editor to show the user right after an image is picked for
    ///   cropping and other sorts of image editing operations.
    ///   - avatarUpdatedHandler: (Optional) A callback to execute when a different avatar is selected.
    ///   - onDismiss: (Optional) A callback to execute when the sheet is dismissed.
    /// - Returns: A modifier to display the QuickEditor sheet.
    @available(iOS 16.0, *)
    public func gravatarQuickEditorSheet(
        isPresented: Binding<Bool>,
        email: String,
        authToken: String? = nil,
        scope: QuickEditorScope,
        customImageEditor: ImageEditorBlock<some ImageEditorView>? = nil as NoCustomEditorBlock?,
        avatarUpdatedHandler: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        switch scope {
        case .avatarPicker(let config):
            let editor = QuickEditor(
                email: .init(email),
                scope: scope.scopeType,
                token: authToken,
                isPresented: isPresented,
                customImageEditor: customImageEditor,
                contentLayoutProvider: config.contentLayout,
                avatarUpdatedHandler: avatarUpdatedHandler
            )
            return modifier(AvatarPickerModalPresentationModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                modalView: editor,
                contentLayout: config.contentLayout
            ))
        }
    }

    func altTextSheet(
        model: Binding<AvatarImageModel?>,
        email: Email,
        toastManager: ToastManager,
        colorScheme: ColorScheme,
        onSave: @escaping (AvatarImageModel) async -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        func altTextEditor(with model: AvatarImageModel) -> some View {
            NavigationView {
                AltTextEditorView(avatar: model, email: email, toastManager: toastManager, onSave: onSave, onCancel: onCancel)
            }
            .colorScheme(colorScheme)
        }

        if #available(iOS 16.0, *) {
            return self.sheet(item: model, onDismiss: onCancel) { selectedModel in
                altTextEditor(with: selectedModel).presentationDetents([.height(AltTextEditorView.Constants.sheetHeight)])
            }
        } else {
            return modifier(
                ModalItemPresentationModifier(
                    item: model,
                    onDismiss: onCancel,
                    modalView: altTextEditor
                )
            )
        }
    }

    func presentationContentInteraction(shouldPrioritizeScrolling: Bool) -> some View {
        if #available(iOS 16.4, *) {
            let behavior: PresentationContentInteraction = shouldPrioritizeScrolling ? .scrolls : .automatic
            return self
                .presentationContentInteraction(behavior)
        } else {
            return self
        }
    }

    /// Applies detents for iOS 16+.
    func presentationDetentsIfAvailable(_ detents: [QEDetent]) -> some View {
        if #available(iOS 16.0, *) {
            return self.presentationDetents(detents.map())
        } else {
            return self
        }
    }

    /// Caution: `InnerHeightPreferenceKey` accumulates the values so DO NOT use this on  a View and one of its ancestors at the same time.
    @ViewBuilder
    func accumulateIntrinsicHeight<K>(key: K.Type = InnerHeightPreferenceKey.self) -> some View where K: PreferenceKey, K.Value == CGFloat {
        self.background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: key,
                    value: proxy.size.height
                )
            }
        }
    }

    @ViewBuilder
    public func imagePlaygroundSheetIfAvailable(
        isPresented: Binding<Bool>,
        sourceImage: Image? = nil,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        if #available(iOS 18.2, *) {
            self.imagePlaygroundSheet(isPresented: isPresented, sourceImage: sourceImage, onCompletion: onCompletion, onCancellation: onCancellation)
        } else {
            self
        }
    }

    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func presentSafariView(identifiableURL: Binding<IdentifiableURL?>, colorScheme: ColorScheme) -> some View {
        self.sheet(item: identifiableURL) { identifiableURL in
            SafariView(url: identifiableURL.url)
                .edgesIgnoringSafeArea(.all)
                .colorScheme(colorScheme)
        }
    }
}
