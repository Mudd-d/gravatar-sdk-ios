@testable import GravatarUI
import SnapshotTesting
import SwiftUI
import XCTest

final class AvatarPickerProfileViewTests: XCTestCase {
    private static let width: CGFloat = 320

    override func invokeTest() {
        withSnapshotTesting(record: .failed) {
            super.invokeTest()
        }
    }

    @MainActor
    func testAvatarPickerProfileView() throws {
        let testView =
            VStack(alignment: .leading, content: {
                AvatarPickerProfileView(
                    avatarID: .constant(.email("")),
                    forceRefreshAvatar: .constant(false),
                    model: .constant(
                        .init(
                            displayName: "Shelly Kimbrough",
                            location: "San Antonio, TX",
                            profileURL: URL(string: "https://gravatar.com"),
                            pronunciation: "SHEL-ee",
                            pronouns: "she/her"
                        )
                    ),
                    isLoading: .constant(false)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            })
            .frame(minWidth: Self.width)

        assertSnapshots(
            of: testView,
            as: [
                .testStrategy(userInterfaceStyle: .light, layout: .sizeThatFits),
                .testStrategy(userInterfaceStyle: .dark, layout: .sizeThatFits),
            ]
        )
    }

    @MainActor
    func testAvatarPickerProfileViewEmpty() throws {
        let testView =
            VStack(alignment: .leading, content: {
                AvatarPickerProfileView(
                    avatarID: .constant(.email("")),
                    forceRefreshAvatar: .constant(false),
                    model: .constant(nil),
                    isLoading: .constant(false)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            })
            .frame(minWidth: Self.width)

        assertSnapshots(
            of: testView,
            as: [
                .testStrategy(userInterfaceStyle: .light, layout: .sizeThatFits),
                .testStrategy(userInterfaceStyle: .dark, layout: .sizeThatFits),
            ]
        )
    }
}
