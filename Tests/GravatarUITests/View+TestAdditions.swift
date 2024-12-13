import SwiftUI

extension View {
    func markBounds() -> some View {
        self
            .padding(1) // to prevent borders from intersecting with content
            .clipShape(RoundedRectangle(cornerSize: .zero))
            .overlay(
                RoundedRectangle(cornerSize: .zero)
                    .stroke(.red, lineWidth: 1)
            )
    }
}
