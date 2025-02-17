import Foundation
import SwiftUI

/// Presentation styles supported for the verticially scrolling content.
public enum VerticalContentPresentationStyle: Sendable, Equatable {
    public static let expandableMediumInitialFraction: CGFloat = 0.7

    /// Full height sheet.
    case large

    /// Medium height sheet that is expandable to full height. In compact height this is inactive and the sheet is displayed as full height.
    /// - initialFraction: The fractional height of the sheet in its initial state.
    /// - prioritizeScrollOverResize: A behavior that prioritizes scrolling the content of the sheet when
    /// swiping, rather than resizing it. Note that this parameter is effective only for iOS 16.4 +.
    case expandableMedium(initialFraction: CGFloat = VerticalContentPresentationStyle.expandableMediumInitialFraction, prioritizeScrollOverResize: Bool = false)
}

/// Presentation styles supported for the horizontially scrolling content.
public enum HorizontalContentPresentationStyle: String, Sendable, Equatable {
    /// Represents a bottom sheet with intrinsic height.
    ///
    /// There are 2 size classes where this mode is inactive:
    ///  - Compact height: The sheet is displayed in full height.
    ///  - Regular width: The system ignores the intrinsic height and defaults to a full size sheet which is
    ///  something out of our control so the content is displayed as a verticially scrolling grid.
    case intrinsicHeight
}

/// Content layout to use iOS 16.0 +.
public enum AvatarPickerContentLayout: AvatarPickerContentLayoutProviding, Equatable {
    /// Displays avatars in a vertcally scrolling grid with the given presentation style. See: ``VerticalContentPresentationStyle``
    case vertical(presentationStyle: VerticalContentPresentationStyle = .large)

    /// Displays avatars in a horizontally scrolling grid with the given presentation style. The grid constists of 1 row . See:
    /// ``HorizontalContentPresentationStyle``
    case horizontal(presentationStyle: HorizontalContentPresentationStyle = .intrinsicHeight)

    // MARK: AvatarPickerContentLayoutProviding

    var contentLayout: AvatarPickerContentLayoutType {
        switch self {
        case .horizontal:
            .horizontal
        case .vertical:
            .vertical
        }
    }

    var prioritizeScrollOverResize: Bool {
        switch self {
        case .vertical(.expandableMedium(_, let prioritizeScrollOverResize)):
            prioritizeScrollOverResize
        default:
            false
        }
    }

    var shareSheetInitialDetent: QEDetent {
        switch self {
        case .vertical(presentationStyle: let presentationStyle):
            switch presentationStyle {
            case .expandableMedium(let initialFraction, _):
                .fraction(initialFraction)
            case .large:
                .medium
            }
        case .horizontal:
            .fraction(VerticalContentPresentationStyle.expandableMediumInitialFraction)
        }
    }
}

/// Content layout to use pre iOS 16.0 where the system don't offer different presentation styles for SwiftUI.
/// Use ``AvatarPickerContentLayout`` for iOS 16.0 +.
enum AvatarPickerContentLayoutType: String, CaseIterable, Identifiable, AvatarPickerContentLayoutProviding {
    var id: Self { self }

    /// Displays avatars in a vertcally scrolling grid.
    case vertical
    /// Displays avatars in a horizontally scrolling grid that consists of 1 row.
    case horizontal

    // MARK: AvatarPickerContentLayoutProviding

    var contentLayout: AvatarPickerContentLayoutType { self }

    var shareSheetInitialDetent: QEDetent {
        .fraction(VerticalContentPresentationStyle.expandableMediumInitialFraction)
    }
}

/// Internal type. This is an abstraction over `AvatarPickerContentLayoutType` and `AvatarPickerContentLayout`
/// to use when all we are interested is to find out if the content is horizontial or vertical.
protocol AvatarPickerContentLayoutProviding: Sendable {
    var contentLayout: AvatarPickerContentLayoutType { get }
    // Determines the initial detent of share sheet inside the QE.
    var shareSheetInitialDetent: QEDetent { get }
}
