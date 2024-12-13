@testable import GravatarUI
import SnapshotTesting
import SwiftUI
import XCTest

final class AvatarPickerProfileViewTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .failed) {
            super.invokeTest()
        }
    }

    @MainActor
    func testAvatarPickerProfileView() throws {
        let testView = AvatarPickerProfileView(
            avatarURL: .constant(nil),
            model: .constant(
                .init(
                    displayName: "Shelly Kimbrough",
                    location: "San Antonio, TX",
                    profileURL: URL(string: "https://gravatar.com")
                )
            ),
            isLoading: .constant(false)
        )
        // put a border around so the bounds can be visible in the snapshots.
        .markBounds()

        assertSnapshots(
            of: testView,
            as: [
                .testStrategy(userInterfaceStyle: .light),
                .testStrategy(userInterfaceStyle: .dark),
            ]
        )
    }
}
