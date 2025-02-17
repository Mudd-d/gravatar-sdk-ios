import GravatarUI
import SnapshotTesting
import XCTest

final class PersonalInfoBuilderTests: XCTestCase {
    let frame = CGRect(x: 0, y: 0, width: 320, height: 200)
    let frameSmall = CGRect(x: 0, y: 0, width: 100, height: 200)
    let palettesToTest: [PaletteType] = [.light, .dark]

    override func invokeTest() {
        withSnapshotTesting(record: .failed) {
            super.invokeTest()
        }
    }

    @MainActor
    func testPersonalInfoEmpty() {
        let label = UILabel(frame: frame)
        Configure(label)
            .asPersonalInfo()
            .content(TestPersonalInfo.empty())
        XCTAssertEqual(label.text, "")
    }

    @MainActor
    func testPersonalInfoSkipsSeparatorAndNewLine() {
        let label = UILabel(frame: frame)
        let testData = TestPersonalInfo(jobTitle: "Engineer", pronunciation: "")
        Configure(label)
            .asPersonalInfo()
            .content(
                testData,
                lines: [
                    .init([.namePronunciation, .jobTitle]),
                    .init([.location]),
                ]
            )
        XCTAssertEqual(label.text, "Engineer", "Do not put unnecessary separator or new line.")
    }

    @MainActor
    func testPersonalInfoFull() {
        let label = UILabel(frame: frame)
        for palette in palettesToTest {
            Configure(label)
                .asPersonalInfo()
                .content(TestPersonalInfo.fullInfo())
                .palette(palette)
            assertSnapshot(of: label, as: .image, named: "testPersonalInfoFull-\(palette.name)")
        }
    }

    @MainActor
    func testPersonalInfoCustom() {
        let label = UILabel(frame: frame)
        for palette in palettesToTest {
            Configure(label)
                .asPersonalInfo()
                .content(TestPersonalInfo.fullInfo(), lines: [
                    .init([.namePronunciation, .jobTitle]),
                    .init([.location]),
                ], separator: " - ")
                .palette(palette)
            assertSnapshot(of: label, as: .image, named: "testPersonalInfoFull-\(palette.name)")
        }
    }

    @MainActor
    func testPersonalInfoWithSmallWidth() {
        let label = UILabel(frame: frameSmall)
        Configure(label)
            .asPersonalInfo()
            .content(TestPersonalInfo.fullInfo())
            .palette(.light)
        assertSnapshot(of: label, as: .image)
    }

    @MainActor
    func testPersonalInfoSkipsSeparatorWithPronounsOnly() {
        let label = UILabel(frame: frame)
        let testData = TestPersonalInfo.pronounsOnly()
        Configure(label)
            .asPersonalInfo()
            .content(testData)

        XCTAssertEqual(label.text, "she/her", "Do not put unnecessary separator")
    }

    @MainActor
    func testPersonalInfoFullText() {
        let label = UILabel(frame: frame)
        Configure(label)
            .asPersonalInfo()
            .content(TestPersonalInfo.fullInfo())

        XCTAssertEqual(label.text, "Carpenter\nCar-N・she/her・Connecticut", "Do not put unnecessary separator")
    }
}

struct TestPersonalInfo: PersonalInfoModel {
    var jobTitle: String = ""
    var pronunciation: String = ""
    var pronouns: String = ""
    var location: String = ""

    static func fullInfo() -> TestPersonalInfo {
        TestPersonalInfo(jobTitle: "Carpenter", pronunciation: "Car-N", pronouns: "she/her", location: "Connecticut")
    }

    static func pronounsOnly() -> TestPersonalInfo {
        TestPersonalInfo(pronouns: "she/her")
    }

    static func empty() -> TestPersonalInfo {
        TestPersonalInfo()
    }
}
