import Foundation

import Combine
import SwiftUI

enum AltTextModalPresentationConstants {
    // Estimated height for the bottom sheet in horizontal mode.
    // The value is the height of a successfully loading Avatar picker in various iPhone models.
    // This is just the initial value of the bottom sheet. If the content turns out to be
    // smaller or bigger, it'll just adjust.
    static let bottomSheetEstimatedHeight: CGFloat = 338

    // This is the minimum height for the avatar picker bottom sheet in the horizontal mode.
    // This also helps us to ignore insignificant values published by the `InnerHeightPreferenceKey`.
    static let bottomSheetMinHeight: CGFloat = 250
}

@available(iOS 16.0, *)
struct AltTextModalPresentationModifier<ModalView: View>: ViewModifier, AltTextModalPresentationWithIntrinsicSize {
    fileprivate typealias Constants = AltTextModalPresentationConstants
    @Binding var isPresented: Bool
    @State private var isPresentedInner: Bool
    @State private var sheetHeight: CGFloat = Constants.bottomSheetEstimatedHeight
    @State private(set) var verticalSizeClass: UserInterfaceSizeClass?
    @State private var presentationDetents: Set<PresentationDetent>
    @State private var prioritizeScrollOverResize: Bool = false
    let onDismiss: (() -> Void)?
    let modalView: ModalView

    init(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, modalView: ModalView) {
        self._isPresented = isPresented
        self.isPresentedInner = isPresented.wrappedValue
        self.onDismiss = onDismiss
        self.modalView = modalView
        self.presentationDetents = Self.detents(for: Constants.bottomSheetEstimatedHeight).map()
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    // First init the detents and then present. This helps with starting off with the correct state.
                    // Otherwise the view remembers its previous height. And an animation glitch happens
                    // when switching between different presentation styles (especially between horizontal and vertical_large).
                    // Doing the same thing in .onAppear of the "modalView" doesn't give as nice results as this one don't know why.
                    self.presentationDetents = Self.detents(for: sheetHeight).map()
                }
                isPresentedInner = newValue
            }
            .onChange(of: isPresentedInner) { newValue in
                self.isPresented = newValue
            }
            .sheet(isPresented: $isPresentedInner, onDismiss: onDismiss) {
                modalView
                    .frame(minHeight: Constants.bottomSheetMinHeight)
                    .onPreferenceChange(AltTextHeightPreferenceKey.self) { newHeight in
                        if shouldAcceptHeight(newHeight) {
                            sheetHeight = newHeight
                        }
                        updateDetents()
                    }
                    .onPreferenceChange(VerticalSizeClassPreferenceKey.self) { newSizeClass in
                        guard newSizeClass != nil else { return }
                        self.verticalSizeClass = newSizeClass
                        updateDetents()
                    }
                    .presentationDetents(presentationDetents)
            }
    }

    private func updateDetents() {
        self.presentationDetents = Self.detents(for: sheetHeight).map()
    }

    private static func detents(for height: CGFloat) -> [QEDetent] {
        [QEDetent.height(max(height, Constants.bottomSheetEstimatedHeight))]
    }
}

@MainActor
protocol AltTextModalPresentationWithIntrinsicSize {
    var verticalSizeClass: UserInterfaceSizeClass? { get }
}

extension AltTextModalPresentationWithIntrinsicSize {
    func shouldAcceptHeight(_ newHeight: CGFloat) -> Bool {
        newHeight > QEModalPresentationConstants.bottomSheetMinHeight && shouldUseIntrinsicSize
    }

    var shouldUseIntrinsicSize: Bool {
        switch verticalSizeClass {
            case .compact:
                false
            default:
                true
        }
    }
}

