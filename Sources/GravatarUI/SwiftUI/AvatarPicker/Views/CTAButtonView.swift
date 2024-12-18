import SwiftUI

struct CTAButtonView: View {
    let title: String
    @Environment(\.isEnabled) var isEnabled

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.callout).fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding(.vertical, .DS.Padding.split)
            .padding(.horizontal, .DS.Padding.double)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: isEnabled ? .gravatarBlue : UIColor.systemFill))
            )
    }
}

#Preview {
    CTAButtonView("I am a button")
        .padding()
    CTAButtonView("I am a disabled button")
        .padding()
        .disabled(true)
}

#Preview("Dark mode") {
    CTAButtonView("I am a button")
        .padding()
        .preferredColorScheme(.dark)
}
