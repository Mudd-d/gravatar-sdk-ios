import SnapshotTesting
import UIKit

extension Snapshotting where Value == UIView, Format == UIImage {
    /// `.image`, but tolerant of the text metric differences between the macOS build a reference was recorded on and
    /// the one the CI VM runs.
    ///
    /// For example, the personal info line — `job • pronouns • location` — lays out with slightly different spacing around the
    /// separators between macOS 26 builds, shifting the rest of the line by a pixel or two. Every view that renders it
    /// differs on CI; views without it match exactly. The CI VM images move through macOS point releases on their own
    /// schedule, so there is no host to pin to keep an exact match, and references cannot be recorded on CI either —
    /// the simulator sandbox drops those writes.
    ///
    /// The defaults come from measuring the real diffs: the worst affected view still matched on 99.08% of pixels, so
    /// `0.98` clears it with headroom while keeping the allowance well under the ~0.5% of the frame that line occupies
    /// — a regression that removed it would still fail. Pass a lower `precision` only for views small enough that the
    /// line dominates the frame, and say why at the call site.
    static func imageWithHostTolerance(precision: Float = 0.98) -> Snapshotting {
        .image(precision: precision, perceptualPrecision: 0.99)
    }
}
